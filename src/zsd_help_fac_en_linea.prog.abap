*----------------------------------------------------------------------*
* Object Type: Report                                                  *
* Program    : ZSD_HELP_FAC_EN_LINEA                                   *
*                                                                      *
* Project : Facturación en línea                                       *
* Date    : 18.07.2022                                                 *
* Company : Help                                                       *
* Functional Consultants :                                             *
* ABAP Consultants       : VisionOne - Carlos Nievas                   *
*                                                                      *
* General Description:                                                 *
* Flujo de facturación completo capturando los datos desde una tabla   *
* en base de datos externa hasta el envío al SII                       *
*----------------------------------------------------------------------*
* Modifications:                                                       *
* Date:                                                                *
* Author:                                                              *
* Description:                                                         *
*----------------------------------------------------------------------*
REPORT zsd_help_fac_en_linea MESSAGE-ID zsdh LINE-SIZE 350.

INCLUDE zsd_help_fac_en_linea_top.  "Declaraciones globales
INCLUDE zsd_help_fac_en_linea_sel.  "Pantalla de inicio
INCLUDE zsd_help_fac_en_linea_def.  "Definiciones de clases
INCLUDE zsd_help_fac_en_linea_imp.  "Implementaciones de clases


*--------------------------------------------------------------------*
*                     START-OF-SELECTION
*--------------------------------------------------------------------*
START-OF-SELECTION.

  CLEAR: gv_rc, gt_data, gt_log.

* Se conecta a la base de datos externa
  DATA(go_dbexterna) = NEW lcl_dbexterna( ).
  go_dbexterna->conectar( IMPORTING ev_rc = gv_rc ).
  IF gv_rc <> 0.
*   Error de conexión a la base de datos externa
    MESSAGE i002.
    LEAVE TO SCREEN 0.
  ENDIF.
* Recupera registros de la tabla externa
  go_dbexterna->leer_datos( IMPORTING et_data = gt_data ).

* Desconecta la base de datos externa
  go_dbexterna->desconectar( ).

  IF gt_data[] IS INITIAL.
*   No se encontraron registros a procesar
    MESSAGE i005.
    LEAVE TO SCREEN 0.
  ENDIF.

  CHECK NOT gt_data[] IS INITIAL.

  DATA(go_proceso) = NEW lcl_proceso( ).

* Borra registros de la tabla Z de respaldo
  go_proceso->del_data( it_data = gt_data ).

* Validación de datos
  CLEAR: gt_log.
  go_proceso->check_data( IMPORTING et_log  = gt_log
                          CHANGING  ct_data = gt_data
                         ).

  IF gt_log[] IS INITIAL.
*   Tratamiento de los datos
    go_proceso->process_data( IMPORTING et_log  = gt_log
                              CHANGING  ct_data = gt_data
                             ).
  ENDIF.

* Conecta a la base de datos externa
  go_dbexterna->conectar( IMPORTING ev_rc = gv_rc ).
  IF gv_rc = 0.
*   Actualización de datos en tabla externa
    go_dbexterna->act_datos( it_data = gt_data ).
    go_dbexterna->desconectar( ).
*   Se eliminan registros de la tabla Z respaldo
    go_proceso->del_data( it_data = gt_data ).
  ENDIF.

* Respaldo de datos
  go_proceso->back_data( it_data = gt_data ).

* Log
  go_proceso->show_log( it_data = gt_data ).

*  cl_demo_output=>display( gt_data ).
