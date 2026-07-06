*&---------------------------------------------------------------------*
*&  Include           ZSD_HELP_FAC_EN_LINEA_DEF
*&---------------------------------------------------------------------*
CLASS lcl_dbexterna DEFINITION FINAL.

  PUBLIC SECTION.
    CONSTANTS: lc_par_bd_name TYPE rvari_val_255
                              VALUE 'ZSD_HELP_FAC_EN_LINEA_CONN',
               lc_par_max_reg TYPE rvari_val_255
                              VALUE 'ZSD_HELP_FAC_EN_LINEA_MAX_REG'.

    DATA: lv_stat_conn TYPE abap_bool,
          lv_name_conn TYPE dbcon_name.

    METHODS:
      conectar     EXPORTING ev_rc   TYPE sysubrc,
      leer_datos   EXPORTING et_data TYPE gtt_data,
      act_datos    IMPORTING it_data TYPE gtt_data,
      desconectar.

ENDCLASS.

CLASS lcl_proceso DEFINITION FINAL.

  PUBLIC SECTION.

    METHODS:

      process_data EXPORTING et_log  TYPE gtt_log
                   CHANGING  ct_data TYPE gtt_data,

      check_data EXPORTING et_log  TYPE gtt_log
                 CHANGING  ct_data TYPE gtt_data,

      save_data IMPORTING it_data TYPE gtt_data,

      del_data  IMPORTING it_data TYPE gtt_data,

      back_data IMPORTING it_data TYPE gtt_data,

      show_log  IMPORTING it_data TYPE gtt_data.

  PRIVATE SECTION.

    METHODS:

      crear_pedido IMPORTING is_data TYPE gty_data
                   EXPORTING es_log  TYPE gty_log,

      crear_factura IMPORTING is_data TYPE gty_data
                    EXPORTING es_log  TYPE gty_log,

      exec_idcp     IMPORTING is_data  TYPE gty_data
                              iv_lotno TYPE lotno
                              iv_bokno TYPE bokno
                              iv_kschl TYPE kschl
                    EXPORTING es_log   TYPE gty_log.

ENDCLASS.

CLASS lcl_cliente DEFINITION FINAL.

  PUBLIC SECTION.

    METHODS:
      extender_cliente_soc IMPORTING is_data    TYPE gty_data
                                     is_cliente TYPE gty_cliente
                           EXPORTING es_log     TYPE gty_log,

      extender_cliente_av IMPORTING is_data    TYPE gty_data
                                     is_cliente TYPE gty_cliente
                           EXPORTING es_log     TYPE gty_log,

      crear_cliente IMPORTING is_data TYPE gty_data
                    EXPORTING es_log  TYPE gty_log.

ENDCLASS.
