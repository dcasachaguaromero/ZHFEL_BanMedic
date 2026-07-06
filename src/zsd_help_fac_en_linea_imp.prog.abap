*&---------------------------------------------------------------------*
*&  Include           ZSD_HELP_FAC_EN_LINEA_IMP
*&---------------------------------------------------------------------*
CLASS lcl_dbexterna IMPLEMENTATION.

  METHOD conectar.
*   Buscar parámetro de conexión en TVARV
    DATA: lv_conn    TYPE dbcon_name.

    CLEAR: ev_rc.

    SELECT SINGLE FROM tvarvc FIELDS low
      WHERE name = @lc_par_bd_name
        AND type = 'P'
        AND numb = '0000'
      INTO @DATA(lv_low).

    IF sy-subrc <> 0.
      lv_stat_conn = abap_false.
      ev_rc = sy-subrc.
      RETURN.
    ENDIF.

    lv_conn = lv_low.

    TRY.
        EXEC SQL.
          CONNECT TO :lv_conn AS 'CON'
        ENDEXEC.
        EXEC SQL.
          SET CONNECTION 'CON'
        ENDEXEC.

      CATCH cx_sy_native_sql_error.
        lv_stat_conn = abap_false.
        ev_rc = 4.
        RETURN.
    ENDTRY.

    lv_stat_conn = abap_true.

  ENDMETHOD.


  METHOD leer_datos.

    DATA: ls_data       TYPE zst_sd_faenli_data.

    DATA: lv_status_fin TYPE c LENGTH 2 VALUE '04',
          lv_max_reg    TYPE sytabix.

    DATA: o_ref TYPE REF TO cx_sy_native_sql_error.

    IF lv_stat_conn = abap_false.
      RETURN.
    ENDIF.

*   Leer máxima cantidad de registros a procesar
    SELECT SINGLE FROM tvarvc FIELDS low
      WHERE name = @lc_par_max_reg
        AND type = 'P'
        AND numb = '0000'
      INTO @DATA(lv_low).

    IF sy-subrc = 0.
      lv_max_reg = lv_low + 1.
    ELSE.
      lv_max_reg = 500.
    ENDIF.

    TRY.
        EXEC SQL.
          OPEN dbcur FOR
            SELECT * FROM RRHH_CSC.factondemand
              WHERE ondestadoproc <> :lv_status_fin
        ENDEXEC.

        DO.
          EXEC SQL.
            FETCH NEXT dbcur INTO :ls_data
          ENDEXEC.
          IF sy-subrc <> 0.
            EXIT.
          ELSE.
            APPEND ls_data TO et_data.
          ENDIF.
        ENDDO.
        EXEC SQL.
          CLOSE dbcur
        ENDEXEC.

      CATCH cx_sy_native_sql_error INTO o_ref.
        DATA(lv_text) = o_ref->get_text( ).
        MESSAGE `Error in Native SQL.` TYPE 'I'.
    ENDTRY.

    IF NOT et_data[] IS INITIAL.
      SORT et_data BY trxid.
      DELETE et_data FROM lv_max_reg.
*     Tabla que puede haber quedado con registros por alguna caída
      SELECT FROM zsd_t_faenli_h FIELDS *
        FOR ALL ENTRIES IN @et_data
        WHERE trxid = @et_data-trxid
        INTO TABLE @DATA(lt_faenli_h).
    ENDIF.

*    CHECK NOT lt_faenli_h[] IS INITIAL.

*   Si quedaron registros sin actualizar en la tabla externa se toman
*   de la tabla Z local
    LOOP AT et_data ASSIGNING FIELD-SYMBOL(<ls_et_data>).
      READ TABLE lt_faenli_h ASSIGNING FIELD-SYMBOL(<ls_faenli_h>)
        WITH KEY trxid = <ls_et_data>-trxid.
      IF sy-subrc = 0.
        MOVE-CORRESPONDING <ls_faenli_h> TO <ls_et_data>.
      ENDIF.
    ENDLOOP.

*    CLEAR: et_data.

*    APPEND INITIAL LINE TO et_data ASSIGNING FIELD-SYMBOL(<ls_data>).
*    <ls_data>-trxid = '736936'.
*    <ls_data>-bukrs = 'CL51'.
*    <ls_data>-vkorg = 'CL51'.
*    <ls_data>-vtweg = '02'.
*    <ls_data>-spart = '00'.
*    <ls_data>-stcd1 = '26421886-1'.
*    <ls_data>-ktokd = 'Z001'.
*    <ls_data>-name1 = 'RAMÓN JOSE'.
*    <ls_data>-name2 = 'FATIGA VAZQUEZ'.
*    <ls_data>-street = 'AV. LOS CARANCHOS'.
*    <ls_data>-str_suppl1 = '26421886-1'.
*    <ls_data>-house_num1 = '3431'.
*    <ls_data>-city2 = 'RECOLETA'.
*    <ls_data>-city1 = 'SANTIAGO'.
*    <ls_data>-country = 'CL'.
*    <ls_data>-region = '13'.
*    <ls_data>-giro = 'VENTA DE ELEMENTOS ELECTRICOS'.
*    <ls_data>-telephone = '223459739'.
*    <ls_data>-movil = '932129834'.
*    <ls_data>-akont = '1011920055'.
*    <ls_data>-zuawa = '000'.
*    <ls_data>-fdgrv = 'E1'.
*    <ls_data>-zterm = 'ZC01'.
*    <ls_data>-zwels = '1'.
*    <ls_data>-xzver = 'X'.
*    <ls_data>-ktgrd = '01'.
*    <ls_data>-taxkd = '1'.
*    <ls_data>-auart = 'ZBOL'.
*    <ls_data>-vkbur = '  '.
*    <ls_data>-bstdk = '20220810'.
*    <ls_data>-kvgr1 = '01'.
*    <ls_data>-kvgr2 = '01'.
*    <ls_data>-werks = '5101'.
*    <ls_data>-matnr = '000000000000000042'.
*    <ls_data>-zmeng = '1'.
*    <ls_data>-kwert = '6000000'.
*    <ls_data>-stpro = '00'.
*    IF <ls_data>-stpro IS INITIAL.
*      <ls_data>-stpro = '00'.
*    ENDIF.
*    <ls_data>-kunnr = '0100047432'.
**    <ls_data>-VBELN_VA
**    <ls_data>-VBELN_VF

  ENDMETHOD.

  METHOD act_datos.
* -> it_data TYPE gtt_data
    DATA: ls_data TYPE gty_data.
    DATA: o_ref TYPE REF TO cx_sy_native_sql_error.

    LOOP AT it_data INTO ls_data.
      TRY.
          EXEC SQL.
            UPDATE RRHH_CSC.factondemand
              SET ondestadoproc  = :ls_data-stpro,
                  ondnroclisap   = :ls_data-kunnr,
                  ondpedidosap   = :ls_data-vbeln_va,
                  ondfacturasap  = :ls_data-vbeln_vf,
                  ondfoliolegal  = :ls_data-xblnr,
                  ondurlpdf      = :ls_data-urlpdf,
                  ondfechaultmod = :ls_data-aedat,
                  ondhoraultmod  = :ls_data-erzet,
                  ondusuultmod   = :ls_data-aenam,
                  ondultmsje     = :ls_data-message
              WHERE ondvoucher = :ls_data-trxid
          ENDEXEC.
        CATCH cx_sy_native_sql_error INTO o_ref.
          DATA(lv_text) = o_ref->get_text( ).
          MESSAGE `Error in Native SQL.` TYPE 'I'.
      ENDTRY.
    ENDLOOP.
    IF sy-subrc = 0.
      COMMIT WORK.
    ENDIF.

  ENDMETHOD.

  METHOD desconectar.
    IF lv_stat_conn = abap_true.
      EXEC SQL.
        DISCONNECT 'CON'
      ENDEXEC.
    ENDIF.
  ENDMETHOD.

ENDCLASS.

CLASS lcl_proceso IMPLEMENTATION.

  METHOD check_data.
* <- et_log   TYPE gtt_log
* <-> it_data TYPE gtt_data
    TYPES: BEGIN OF lty_pais,
             land1 TYPE land1,
           END OF lty_pais,

           BEGIN OF lty_mara,
             matnr TYPE matnr,
           END OF lty_mara,

           ltt_pais TYPE STANDARD TABLE OF lty_pais,
           ltt_mara TYPE STANDARD TABLE OF lty_mara.

    DATA: lt_pais TYPE ltt_pais,
          lt_mara TYPE ltt_mara.

    DATA: lr_stpro TYPE RANGE OF zde_stpro.

*   Solo valida los registros nuevos o con errores previos
    lr_stpro = VALUE #( sign   = 'I'
                        option = 'EQ'
                        ( low    = '00' )
                        ( low    = '20' )
                       ).

    LOOP AT ct_data ASSIGNING FIELD-SYMBOL(<ls_data>).
      APPEND INITIAL LINE TO lt_pais ASSIGNING FIELD-SYMBOL(<ls_pais>).
      <ls_pais>-land1 = <ls_data>-country.

      APPEND INITIAL LINE TO lt_mara ASSIGNING FIELD-SYMBOL(<ls_mara>).
      <ls_mara>-matnr = <ls_data>-matnr.

      IF <ls_data>-stpro IS INITIAL.
        <ls_data>-stpro = '00'.
      ENDIF.
    ENDLOOP.

*   Para validar paises
    SORT lt_pais BY land1.
    DELETE ADJACENT DUPLICATES FROM lt_pais COMPARING land1.

*   Para validar regiones
    IF NOT lt_pais[] IS INITIAL.
      SELECT FROM t005s FIELDS land1, bland
        FOR ALL ENTRIES IN @lt_pais
        WHERE land1 = @lt_pais-land1
        INTO TABLE @DATA(lt_region).
    ENDIF.

*   Para validar materiales
    SORT lt_mara BY matnr.
    DELETE ADJACENT DUPLICATES FROM lt_mara COMPARING matnr.
    LOOP AT lt_mara ASSIGNING <ls_mara>.
      CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
        EXPORTING
          input        = <ls_mara>-matnr
        IMPORTING
          output       = <ls_mara>-matnr
        EXCEPTIONS
          length_error = 1
          OTHERS       = 2.
    ENDLOOP.

    IF NOT lt_mara[] IS INITIAL.
      SELECT FROM mara FIELDS matnr
        FOR ALL ENTRIES IN @lt_mara
        WHERE matnr = @lt_mara-matnr
        INTO TABLE @DATA(lt_mat).
    ENDIF.

*   Recorre registro por registro
    LOOP AT ct_data ASSIGNING <ls_data> WHERE stpro IN lr_stpro.
      <ls_data>-stpro = '00'.
*     Formatea RUT
      TRANSLATE <ls_data>-stcd1 USING '. '.
      CONDENSE <ls_data>-stcd1 NO-GAPS.
*     Valida país
      READ TABLE lt_pais TRANSPORTING NO FIELDS WITH KEY land1 = <ls_data>-country.
      IF sy-subrc <> 0.
        <ls_data>-message = |{ TEXT-e01 } COUNTRY |.
        <ls_data>-stpro   = '20'.
        CONTINUE.
      ENDIF.
*     Valida región
      READ TABLE lt_region TRANSPORTING NO FIELDS
        WITH KEY land1 = <ls_data>-country
                 bland = <ls_data>-region.
      IF sy-subrc <> 0.
        <ls_data>-message = |{ TEXT-e01 } REGIÓN |.
        <ls_data>-stpro   = '20'.
        CONTINUE.
      ENDIF.
*     Formatea cuenta
      <ls_data>-akont = |{ <ls_data>-akont ALPHA = IN }|.
*     Formatea material
      CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
        EXPORTING
          input        = <ls_data>-matnr
        IMPORTING
          output       = <ls_data>-matnr
        EXCEPTIONS
          length_error = 1
          OTHERS       = 2.

      IF sy-subrc <> 0.
        <ls_data>-message = |{ TEXT-e01 } MATNR |.
        <ls_data>-stpro   = '20'.
        CONTINUE.
      ENDIF.

*     Busca material
      READ TABLE lt_mat TRANSPORTING NO FIELDS WITH KEY matnr = <ls_data>-matnr.
      IF sy-subrc <> 0.
        <ls_data>-message = |{ TEXT-e02 } MATNR |.
        <ls_data>-stpro   = '20'.
        CONTINUE.
      ENDIF.

*     Cliente
      IF NOT <ls_data>-kunnr IS INITIAL.
        <ls_data>-kunnr = |{ <ls_data>-kunnr ALPHA = IN }|.
      ENDIF.
      IF NOT <ls_data>-vbeln_va IS INITIAL.
        <ls_data>-vbeln_va = |{ <ls_data>-vbeln_va ALPHA = IN }|.
      ENDIF.
      IF NOT <ls_data>-vbeln_vf IS INITIAL.
        <ls_data>-vbeln_vf = |{ <ls_data>-vbeln_vf ALPHA = IN }|.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD save_data.
* -> it_data TYPE gtt_data
    DATA: lt_faenli_h TYPE STANDARD TABLE OF zsd_t_faenli_h.

    LOOP AT it_data ASSIGNING FIELD-SYMBOL(<ls_data>).
      APPEND INITIAL LINE TO lt_faenli_h ASSIGNING FIELD-SYMBOL(<ls_faenli_h>).
      <ls_faenli_h>-mandt = sy-mandt.
      MOVE-CORRESPONDING <ls_data> TO <ls_faenli_h>.
    ENDLOOP.

    MODIFY zsd_t_faenli_h FROM TABLE lt_faenli_h.
    COMMIT WORK AND WAIT.

  ENDMETHOD.

  METHOD del_data.
* -> it_data TYPE gtt_data
    DATA: lr_trxid TYPE RANGE OF zde_trxid.

    lr_trxid = VALUE #( FOR ls_data IN it_data
                               ( sign   = 'I'
                                 option = 'EQ'
                                 low    = ls_data-trxid ) ).


    DELETE FROM zsd_t_faenli_h WHERE trxid IN lr_trxid.
    IF sy-subrc = 0.
      COMMIT WORK AND WAIT.
    ENDIF.

  ENDMETHOD.

  METHOD back_data.

    DATA: lt_faenli_dat TYPE STANDARD TABLE OF zsd_t_faenli_dat.

    LOOP AT it_data ASSIGNING FIELD-SYMBOL(<ls_data>).
      APPEND INITIAL LINE TO lt_faenli_dat ASSIGNING FIELD-SYMBOL(<ls_faenli_dat>).
      MOVE-CORRESPONDING <ls_data> TO <ls_faenli_dat>.
      <ls_faenli_dat>-mandt = sy-mandt.
    ENDLOOP.

    MODIFY zsd_t_faenli_dat FROM TABLE lt_faenli_dat.

  ENDMETHOD.

  METHOD process_data.

    TYPES: BEGIN OF lty_rut,
             stcd1 TYPE stcd1,
           END OF lty_rut.

    TYPES: ltt_rut     TYPE STANDARD TABLE OF lty_rut,
           ltt_cliente TYPE STANDARD TABLE OF gty_cliente.

    DATA: ls_log     TYPE gty_log.

    DATA: lt_data    TYPE gtt_data,
          lt_rut     TYPE ltt_rut,
          lt_cliente TYPE ltt_cliente,
          lt_param   TYPE tvarvc_t.

    DATA: lv_name     TYPE char30 VALUE 'ZSD_HELP_FAC_EN_LINEA_%',
          lv_mesgbol  TYPE kschl,
          lv_mesgfac  TYPE kschl,
          lv_idlb_bea TYPE c LENGTH 4,
          lv_idlb_bee TYPE c LENGTH 4,
          lv_idlb_fea TYPE c LENGTH 4,
          lv_idlb_fee TYPE c LENGTH 4,
          lv_lotno    TYPE lotno,
          lv_bokno    TYPE bokno,
          lv_kschl    TYPE kschl.

    SORT ct_data BY trxid.

*   Se obtiene una copia para trabajar con los registros de la sociedad seleccionada
    lt_data[] = ct_data[].
    DELETE lt_data WHERE bukrs <> p_bukrs.

*   Se buscan los RUT's dejando una sola ocurrencia
    LOOP AT lt_data ASSIGNING FIELD-SYMBOL(<ls_data>).
      APPEND INITIAL LINE TO lt_rut ASSIGNING FIELD-SYMBOL(<ls_rut>).
      <ls_rut>-stcd1 = <ls_data>-stcd1.
    ENDLOOP.
    SORT lt_rut BY stcd1.
    DELETE ADJACENT DUPLICATES FROM lt_rut COMPARING stcd1.

    CHECK NOT lt_rut[] IS INITIAL.

*   Se buscan los datos generales y de sociedad para los RUT's únicos
    SELECT FROM kna1 AS a
      LEFT JOIN knb1 AS b ON a~kunnr = b~kunnr
      FIELDS a~kunnr, b~bukrs, a~stcd1
      FOR ALL ENTRIES IN @lt_rut
      WHERE a~stcd1 = @lt_rut-stcd1
    INTO TABLE @lt_cliente.

    SORT lt_cliente BY kunnr bukrs.

    DATA(lo_cliente) = NEW lcl_cliente( ).

*   Verificar si cliente existe en datos generales
    LOOP AT lt_data ASSIGNING <ls_data> WHERE stpro = '00' OR  "Primera ejecución
                                              stpro = '11' OR  "Error creación cliente central
                                              stpro = '12'.    "Error ampliación cliente
      CLEAR: ls_log.

      READ TABLE lt_cliente ASSIGNING FIELD-SYMBOL(<ls_cli_central>)
        WITH KEY stcd1 = <ls_data>-stcd1.

      IF sy-subrc = 0.
        <ls_data>-kunnr = <ls_cli_central>-kunnr.

*       Verificar si cliente existe en la sociedad
        READ TABLE lt_cliente ASSIGNING FIELD-SYMBOL(<ls_cliente>)
          WITH KEY stcd1 = <ls_data>-stcd1
                   bukrs = <ls_data>-bukrs.

        IF sy-subrc = 0.
*         Cliente existe
          <ls_data>-stpro = '01'.

*         Verificar si existe en el area de ventas
          SELECT SINGLE FROM knvv FIELDS kunnr
            WHERE kunnr = @<ls_data>-kunnr
              AND vkorg = @<ls_data>-vkorg
              AND vtweg = @<ls_data>-vtweg
              AND spart = @<ls_data>-spart
            INTO @DATA(lv_dummy).

          IF sy-subrc <> 0.
*           Extender cliente
            CLEAR: ls_log.
            lo_cliente->extender_cliente_av( EXPORTING is_data    = <ls_data>
                                                       is_cliente = <ls_cli_central>
                                             IMPORTING es_log     = ls_log ).

            IF ls_log-is_error = abap_false.
              <ls_data>-stpro = '01'.

            ELSE.
              <ls_data>-stpro = '12'.
              READ TABLE ls_log-messages ASSIGNING FIELD-SYMBOL(<ls_messages>) INDEX 1.
              IF sy-subrc = 0.
                <ls_data>-message = <ls_messages>-message.
              ENDIF.
            ENDIF.
          ENDIF.
        ELSE.
*         Extender cliente
          CLEAR: ls_log.
          lo_cliente->extender_cliente_soc( EXPORTING is_data    = <ls_data>
                                                      is_cliente = <ls_cli_central>
                                            IMPORTING es_log     = ls_log ).

          IF ls_log-is_error = abap_false.
            <ls_data>-stpro = '01'.
            APPEND INITIAL LINE TO lt_cliente ASSIGNING FIELD-SYMBOL(<ls_new_cliente>).
            <ls_new_cliente>-kunnr = <ls_data>-kunnr.
            <ls_new_cliente>-bukrs = <ls_data>-bukrs.
            <ls_new_cliente>-stcd1 = <ls_data>-stcd1.
          ELSE.
            <ls_data>-stpro = '12'.
            READ TABLE ls_log-messages ASSIGNING <ls_messages> INDEX 1.
            IF sy-subrc = 0.
              <ls_data>-message = <ls_messages>-message.
            ENDIF.
          ENDIF.
        ENDIF.
      ELSE.
*       Crear cliente
        CLEAR: ls_log.
        lo_cliente->crear_cliente( EXPORTING is_data = <ls_data>
                                   IMPORTING es_log  = ls_log ).
        IF ls_log-is_error = abap_false.
          <ls_data>-stpro = '01'.
          READ TABLE ls_log-messages ASSIGNING <ls_messages> INDEX 1.
          IF sy-subrc = 0.
            <ls_data>-kunnr = <ls_messages>-message_v1.
          ENDIF.
        ELSE.
          <ls_data>-stpro = '11'.
          READ TABLE ls_log-messages ASSIGNING <ls_messages> INDEX 1.
          IF sy-subrc = 0.
            <ls_data>-message = <ls_messages>-message.
          ENDIF.
        ENDIF.
      ENDIF.
      <ls_data>-aedat = sy-datum.
      <ls_data>-erzet = sy-uzeit.
      <ls_data>-aenam = sy-uname.
    ENDLOOP.

    CLEAR: lo_cliente.
    save_data( it_data = lt_data ).

*   Crear pedido de ventas
    LOOP AT lt_data ASSIGNING <ls_data> WHERE stpro = '01' OR   "Cliente existente, creado o actualizado
                                              stpro = '13'.     "Error en creación pedido de ventas
      CLEAR: ls_log.
      crear_pedido( EXPORTING is_data    = <ls_data>
                    IMPORTING es_log     = ls_log
                   ).

      IF ls_log-is_error = abap_false.
        <ls_data>-stpro = '02'.  "Pedido de ventas creado
        READ TABLE ls_log-messages ASSIGNING <ls_messages> INDEX 1.
        IF sy-subrc = 0.
          <ls_data>-vbeln_va = <ls_messages>-message_v1.
        ENDIF.
      ELSE.
        <ls_data>-stpro = '13'.
        READ TABLE ls_log-messages ASSIGNING <ls_messages> INDEX 1.
        IF sy-subrc = 0.
          <ls_data>-message = <ls_messages>-message.
        ENDIF.
      ENDIF.

      <ls_data>-aedat = sy-datum.
      <ls_data>-erzet = sy-uzeit.
      <ls_data>-aenam = sy-uname.
    ENDLOOP.

    save_data( it_data = lt_data ).

*   Crear factura
    LOOP AT lt_data ASSIGNING <ls_data> WHERE stpro = '02' OR   "Pedido de ventas creado
                                              stpro = '14'.     "Error en creación de factura
      CLEAR: ls_log.
      crear_factura( EXPORTING is_data    = <ls_data>
                     IMPORTING es_log     = ls_log
                    ).

      IF ls_log-is_error = abap_false.
        <ls_data>-stpro = '03'.  "Factura creada
        READ TABLE ls_log-messages ASSIGNING <ls_messages> INDEX 1.
        IF sy-subrc = 0.
          <ls_data>-vbeln_vf = <ls_messages>-message_v1.
        ENDIF.
      ELSE.
        <ls_data>-stpro = '14'.  "Error en creación de factura
        READ TABLE ls_log-messages ASSIGNING <ls_messages> INDEX 1.
        IF sy-subrc = 0.
          <ls_data>-message = <ls_messages>-message.
        ENDIF.
      ENDIF.

      <ls_data>-aedat = sy-datum.
      <ls_data>-erzet = sy-uzeit.
      <ls_data>-aenam = sy-uname.
    ENDLOOP.

    save_data( it_data = lt_data ).

*   Enviar al SII vía IDCP
*   Recuperar pila y libro desde STVARV
    SELECT FROM tvarvc
      FIELDS substring( name, 23, 8 ) AS name,
             low
      WHERE name LIKE @lv_name
        AND type = 'P'
      INTO CORRESPONDING FIELDS OF TABLE @lt_param.

    LOOP AT lt_param ASSIGNING FIELD-SYMBOL(<ls_param>).
      CASE <ls_param>-name.
        WHEN 'MESGBOL'.  lv_mesgbol  = <ls_param>-low.
        WHEN 'MESGFAC'.  lv_mesgfac  = <ls_param>-low.
        WHEN 'IDLB_BEA'. lv_idlb_bea = <ls_param>-low.
        WHEN 'IDLB_BEE'. lv_idlb_bee = <ls_param>-low.
        WHEN 'IDLB_FEA'. lv_idlb_fea = <ls_param>-low.
        WHEN 'IDLB_FEE'. lv_idlb_fee = <ls_param>-low.
      ENDCASE.
    ENDLOOP.

**
    LOOP AT lt_data ASSIGNING <ls_data> WHERE stpro = '03' OR   "Factura creada
                                              stpro = '15'.     "Error en envío de DTE

      CLEAR: lv_lotno, lv_bokno, lv_kschl, ls_log.

      IF <ls_data>-auart = 'ZBOL'. "Boleta
        lv_kschl = lv_mesgbol.
        IF <ls_data>-kvgr2 = '01'.   "Afecta
          lv_lotno = lv_idlb_bea+0(2).
          lv_bokno = lv_idlb_bea+2(2).
        ELSE.                        "Exenta
          lv_lotno = lv_idlb_bee+0(2).
          lv_bokno = lv_idlb_bee+2(2).
        ENDIF.
      ELSE.                        "Factura
        lv_bokno = '01'.
        lv_kschl = lv_mesgfac.
        IF <ls_data>-kvgr2 = '01'.    "Afecta
          lv_lotno = lv_idlb_fea+0(2).
          lv_bokno = lv_idlb_fea+2(2).
        ELSE.                         "Exenta
          lv_lotno = lv_idlb_fee+0(2).
          lv_bokno = lv_idlb_fee+2(2).
        ENDIF.
      ENDIF.

      SUBMIT zsdrepmsg WITH p_vbeln EQ <ls_data>-vbeln_vf AND RETURN.

      exec_idcp( EXPORTING is_data  = <ls_data>
                           iv_lotno = lv_lotno
                           iv_bokno = lv_bokno
                           iv_kschl = lv_kschl
                 IMPORTING es_log   = ls_log
                ).

*     Actualizar status
      IF ls_log-is_error = abap_false.
        <ls_data>-stpro = '04'.  "Factura enviada al SII
        READ TABLE ls_log-messages ASSIGNING <ls_messages> INDEX 1.
        IF sy-subrc = 0.
          <ls_data>-xblnr = <ls_messages>-message_v1.
          <ls_data>-message = 'Proceso finalizado'.
        ENDIF.

*       Recuperar URL
        SELECT SINGLE FROM bkpf FIELDS bukrs, belnr, gjahr
          WHERE bukrs = @<ls_data>-bukrs
            AND awtyp = 'VBRK'
            AND awkey = @<ls_data>-vbeln_vf
          INTO @DATA(ls_bkpf).
        IF sy-subrc = 0.
          SELECT FROM zfac_anex FIELDS zurl
            WHERE bukrs = @ls_bkpf-bukrs
              AND belnr = @ls_bkpf-belnr
              AND gjahr = @ls_bkpf-gjahr
            INTO TABLE @DATA(lt_anex).
          LOOP AT lt_anex ASSIGNING FIELD-SYMBOL(<ls_anex>).
            IF NOT <ls_anex>-zurl IS INITIAL.
              <ls_data>-urlpdf = <ls_anex>-zurl .
              EXIT.
            ENDIF.
          ENDLOOP.
        ENDIF.

      ELSE.
        <ls_data>-stpro = '15'.
        READ TABLE ls_log-messages ASSIGNING <ls_messages> INDEX 1.
        IF sy-subrc = 0.
          <ls_data>-message = <ls_messages>-message.
        ENDIF.
      ENDIF.

      <ls_data>-aedat = sy-datum.
      <ls_data>-erzet = sy-uzeit.
      <ls_data>-aenam = sy-uname.
    ENDLOOP.

    save_data( it_data = lt_data ).
**
*   Actualizar tabla de salida
    LOOP AT ct_data ASSIGNING FIELD-SYMBOL(<ls_output_data>).
      READ TABLE lt_data ASSIGNING <ls_data> WITH KEY trxid = <ls_output_data>-trxid.
      IF sy-subrc = 0.
        <ls_output_data> = <ls_data>.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD crear_pedido.

    DATA: ls_order_header_in  TYPE bapisdhd1,
          ls_order_header_inx TYPE bapisdhd1x,
          ls_header           TYPE thead.

    DATA: lt_return               TYPE STANDARD TABLE OF bapiret2,
          lt_order_items_in       TYPE STANDARD TABLE OF bapisditm,
          lt_order_items_inx      TYPE STANDARD TABLE OF bapisditmx,
          lt_order_partners       TYPE STANDARD TABLE OF bapiparnr,
          lt_order_schedules_in   TYPE STANDARD TABLE OF bapischdl,
          lt_order_schedules_inx  TYPE STANDARD TABLE OF bapischdlx,
          lt_order_conditions_in  TYPE STANDARD TABLE OF bapicond,
          lt_order_conditions_inx TYPE STANDARD TABLE OF bapicondx,
          lt_lines                TYPE tline_t.

    DATA: lv_salesdocument TYPE vbeln_va.

*   Datos de cabecera
    CLEAR: ls_order_header_in, ls_order_header_inx,
           lt_order_partners, lt_order_items_in, lt_order_items_inx,
           lt_order_schedules_in, lt_order_schedules_inx,
           lt_order_conditions_in, lt_order_conditions_inx.

    ls_order_header_in-doc_type  = is_data-auart.
    ls_order_header_inx-doc_type = abap_true.

    ls_order_header_in-sales_org  = is_data-vkorg.
    ls_order_header_inx-sales_org = abap_true.

    ls_order_header_in-distr_chan  = is_data-vtweg.
    ls_order_header_inx-distr_chan = abap_true.

    ls_order_header_in-division  = is_data-spart.
    ls_order_header_inx-division = abap_true.

    ls_order_header_in-purch_no_c  = is_data-trxid.
    ls_order_header_inx-purch_no_c = abap_true.

    ls_order_header_in-purch_no_s  = is_data-vertn.
    ls_order_header_inx-purch_no_s = abap_true.

    ls_order_header_in-sales_off  = is_data-vkbur.
    ls_order_header_inx-sales_off = abap_true.

    ls_order_header_in-purch_date  = is_data-bstdk.
    ls_order_header_inx-purch_date = abap_true.

    ls_order_header_in-cust_grp1  = is_data-kvgr1.
    ls_order_header_inx-cust_grp1 = abap_true.

    ls_order_header_in-cust_grp2  = is_data-kvgr2.
    ls_order_header_inx-cust_grp2 = abap_true.

*   Datos de interlocutores
    APPEND INITIAL LINE TO lt_order_partners ASSIGNING FIELD-SYMBOL(<ls_partner>).
    <ls_partner>-partn_role = 'AG'.
    <ls_partner>-partn_numb = is_data-kunnr.

    APPEND INITIAL LINE TO lt_order_partners ASSIGNING <ls_partner>.
    <ls_partner>-partn_role = 'RE'.
    <ls_partner>-partn_numb = is_data-kunnr.

    APPEND INITIAL LINE TO lt_order_partners ASSIGNING <ls_partner>.
    <ls_partner>-partn_role = 'RG'.
    <ls_partner>-partn_numb = is_data-kunnr.

    APPEND INITIAL LINE TO lt_order_partners ASSIGNING <ls_partner>.
    <ls_partner>-partn_role = 'WE'.
    <ls_partner>-partn_numb = is_data-kunnr.

*   Posición única
    APPEND INITIAL LINE TO lt_order_items_in ASSIGNING FIELD-SYMBOL(<ls_item>).
    <ls_item>-itm_number = 1.
    <ls_item>-plant      = is_data-werks.
    <ls_item>-material   = is_data-matnr.
    <ls_item>-target_qty = is_data-zmeng.

    APPEND INITIAL LINE TO lt_order_items_inx ASSIGNING FIELD-SYMBOL(<ls_itemx>).
    <ls_itemx>-itm_number = 1.
    <ls_itemx>-plant      = abap_true.
    <ls_itemx>-material   = abap_true.
    <ls_itemx>-target_qty = abap_true.

*   Fechas
    APPEND INITIAL LINE TO lt_order_schedules_in ASSIGNING FIELD-SYMBOL(<ls_schedule>).
    <ls_schedule>-itm_number = 1.
    <ls_schedule>-req_qty    = is_data-zmeng.

    APPEND INITIAL LINE TO lt_order_schedules_inx ASSIGNING FIELD-SYMBOL(<ls_schedulex>).
    <ls_schedulex>-itm_number = 1.
    <ls_schedulex>-updateflag = abap_true.
    <ls_schedulex>-req_qty    = abap_true.

*   Condiciones
    APPEND INITIAL LINE TO lt_order_conditions_in ASSIGNING FIELD-SYMBOL(<ls_condition>).
    <ls_condition>-itm_number = 1.
    <ls_condition>-cond_st_no = 1.
    <ls_condition>-cond_count = 1.
    <ls_condition>-cond_type  = 'ZPR0'.
    <ls_condition>-cond_value = is_data-kwert.
    <ls_condition>-currency   = 'CLP'.

    APPEND INITIAL LINE TO lt_order_conditions_inx ASSIGNING FIELD-SYMBOL(<ls_conditionx>).
    <ls_conditionx>-itm_number = 1.
    <ls_conditionx>-cond_st_no = 1.
    <ls_conditionx>-cond_count = 1.
    <ls_conditionx>-updateflag = abap_true.
    <ls_conditionx>-cond_type  = abap_true.
    <ls_conditionx>-cond_value = abap_true.
    <ls_conditionx>-currency   = abap_true.

    CALL FUNCTION 'BAPI_SALESORDER_CREATEFROMDAT2'
      EXPORTING
        order_header_in      = ls_order_header_in
        order_header_inx     = ls_order_header_inx
      IMPORTING
        salesdocument        = lv_salesdocument
      TABLES
        return               = lt_return
        order_items_in       = lt_order_items_in
        order_items_inx      = lt_order_items_inx
        order_partners       = lt_order_partners
        order_schedules_in   = lt_order_schedules_in
        order_schedules_inx  = lt_order_schedules_inx
        order_conditions_in  = lt_order_conditions_in
        order_conditions_inx = lt_order_conditions_inx.

    IF NOT lv_salesdocument IS INITIAL.
*     Pedido de ventas creado exitosamente
      es_log-is_error = abap_false.
      APPEND INITIAL LINE TO es_log-messages ASSIGNING FIELD-SYMBOL(<ls_message>).
*     Se guarda el número de pedido en la tabla de log
      <ls_message>-message_v1 = lv_salesdocument.

      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          wait = 'X'.

*     Se agrega texto de cabecera VBBK/0002
      CLEAR: ls_header, lt_lines.

      ls_header-tdobject = 'VBBK'.
      ls_header-tdname   = lv_salesdocument.
      ls_header-tdid     = '0002'.
      ls_header-tdspras  = sy-langu.

      APPEND INITIAL LINE TO lt_lines ASSIGNING FIELD-SYMBOL(<fs_lines>).
      <fs_lines>-tdformat = '*'.
      <fs_lines>-tdline   = is_data-maktx.

      CALL FUNCTION 'SAVE_TEXT'
        EXPORTING
          header          = ls_header
          savemode_direct = 'X'
        TABLES
          lines           = lt_lines
        EXCEPTIONS
          id              = 1
          language        = 2
          name            = 3
          object          = 4
          OTHERS          = 5.

      IF sy-subrc <> 0.

      ENDIF.

    ELSE.
      es_log-is_error = abap_true.
      READ TABLE lt_return ASSIGNING FIELD-SYMBOL(<ls_return>) WITH KEY type = 'E'.
      IF sy-subrc = 0.
        APPEND INITIAL LINE TO es_log-messages ASSIGNING <ls_message>.
        MOVE-CORRESPONDING <ls_return> TO <ls_message>.
      ENDIF.
    ENDIF.

  ENDMETHOD.


  METHOD crear_factura.

    DATA: ls_creatordatain  TYPE bapicreatordata.

    DATA: lt_billingdatain TYPE STANDARD TABLE OF bapivbrk,
          lt_return        TYPE STANDARD TABLE OF bapiret1,
          lt_success       TYPE STANDARD TABLE OF bapivbrksuccess.

    DATA: lv_testrun TYPE testrun,
          lv_posting TYPE posting_type_ct.

    SELECT SINGLE FROM vbak
      FIELDS vkorg, vtweg, spart, vbeln, vbtyp
      WHERE vbeln = @is_data-vbeln_va
      INTO @DATA(ls_vbak).

    CHECK sy-subrc = 0.

    ls_creatordatain-created_by = sy-uname.
    ls_creatordatain-created_on = sy-datum.

    lv_testrun = ' '.
    lv_posting = 'D'.
* ' = do not update directly (this is done separately using the function module RV_INVOICE_DOCUMENT_ADD)
*'A' = update directly without error log (VBSK,VBFS) - asynchronous
*'B' = update directly with error log (VBSK,VBFS) - asynchronous
*'C' = update directly without error log (VBSK,VBFS) - synchronous
*'D' = update directly with error log (VBSK,VBFS) - synchronous
*'E' = update directly without error log (VBSK,VBFS) - without commit
*'F' = update directly without error log (VBSK,VBFS) - without commit
*'G' = only for internal use by the POS interface no billing document update, accounting and info system is updated.
*'H' = do not update directly, simulation of billing doc creation and transfer to FI, no final data initialization.

    APPEND INITIAL LINE TO lt_billingdatain ASSIGNING FIELD-SYMBOL(<ls_billingdatain>).
    <ls_billingdatain>-salesorg    = ls_vbak-vkorg.
    <ls_billingdatain>-distr_chan  = ls_vbak-vtweg.
    <ls_billingdatain>-division    = ls_vbak-spart.
    <ls_billingdatain>-ref_doc     = ls_vbak-vbeln.
    <ls_billingdatain>-ref_doc_ca  = ls_vbak-vbtyp.

    CALL FUNCTION 'BAPI_BILLINGDOC_CREATEMULTIPLE'
      EXPORTING
        creatordatain = ls_creatordatain
        testrun       = lv_testrun
        posting       = lv_posting
      TABLES
        billingdatain = lt_billingdatain
        return        = lt_return
        success       = lt_success.

    READ TABLE lt_success ASSIGNING FIELD-SYMBOL(<ls_success>) INDEX 1.
    IF sy-subrc = 0.
*     Factura creada exitosamente
      es_log-is_error = abap_false.
      APPEND INITIAL LINE TO es_log-messages ASSIGNING FIELD-SYMBOL(<ls_message>).
*     Se guarda el número de factura en la tabla de log
      <ls_message>-message_v1 = <ls_success>-bill_doc.

      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          wait = 'X'.

    ELSE.
      es_log-is_error = abap_true.
      READ TABLE lt_return ASSIGNING FIELD-SYMBOL(<ls_return>) WITH KEY type = 'E'.
      IF sy-subrc <> 0.
        APPEND INITIAL LINE TO es_log-messages ASSIGNING <ls_message>.
        MOVE-CORRESPONDING <ls_return> TO <ls_message>.
      ENDIF.
    ENDIF.

  ENDMETHOD.

  METHOD exec_idcp.
*   ->  is_data  TYPE gty_data
*   ->  iv_lotno TYPE lotno
*   ->  iv_bokno TYPE bokno
*   ->  iv_kschl TYPE kschl
*   <-  es_log   TYPE gty_log.

    DATA: ls_options TYPE ctu_params..

    DATA: bdcdata_tab TYPE TABLE OF bdcdata,
          lt_messtab  TYPE TABLE OF bdcmsgcoll.

    DATA: lv_mode   TYPE ctu_mode   VALUE 'N',
          lv_update TYPE ctu_update VALUE 'S',
          lv_name   TYPE c LENGTH 21,
          lv_batch  TYPE sybatch.


    SELECT SINGLE FROM idcn_boma FIELDS bukrs, lotno, bokno
      WHERE bukrs = @is_data-bukrs
        AND lotno = @iv_lotno
        AND bokno = @iv_bokno
      INTO @DATA(ls_libro).

    IF sy-subrc = 0.
      CLEAR bdcdata_tab[].

      bdcdata_tab = VALUE #(
        ( program  = 'IDPRCNINVOICE'     dynpro   = '1000' dynbegin = 'X' )
        ( fnam     = 'BDC_OKCODE'        fval     = '=ONLI'           )
        ( fnam     = 'CHK_BILL'          fval     = 'X'               )
        ( fnam     = 'CHK_PRI'           fval     = 'X'               )
        ( fnam     = 'VKORG'             fval     = is_data-vkorg     )
        ( fnam     = 'LOTNO'             fval     = iv_lotno          )
        ( fnam     = 'BOKNO'             fval     = iv_bokno          )

        ( program  = 'IDPRCNINVOICE'     dynpro   = '0111' dynbegin = 'X' )
        ( fnam     = 'BDC_OKCODE'        fval     = '=CRET'           )
        ( fnam     = 'VBELN-LOW'         fval     = is_data-vbeln_vf  )
        ( fnam     = 'MSG_TYPE'          fval     = iv_kschl          )
        ( fnam     = 'RFBSK_AB'          fval     = ' '               )  "Bloq.contab.
        ( fnam     = 'RFBSK_S'           fval     = 'X'               )  "Interfase FI
        ( fnam     = 'RFBSK_C'           fval     = 'X'               )  "Documento contable creado
        ( fnam     = 'NO_RPRT'           fval     = 'X'               )

        ( program  = 'SAPMSSY0'          dynpro   = '0120' dynbegin = 'X' )
        ( fnam     = 'BDC_OKCODE'        fval     = '=&ALL'           )

        ( program  = 'SAPMSSY0'          dynpro   = '0120' dynbegin = 'X' )
        ( fnam     = 'BDC_OKCODE'        fval     = '=BTCI'           )
        ).

      ls_options-dismode  = lv_mode.
      ls_options-updmode  = lv_update.
      ls_options-defsize  = 'X'.
      ls_options-racommit = 'X'.

      TRY.
          lv_name  = sy-uname && '_' && sy-datum.
          DELETE FROM DATABASE  indx(xy) ID lv_name.
          IF sy-batch EQ 'X'.
            lv_batch = 'X'.
            EXPORT lv_batch = lv_batch TO DATABASE indx(xy) ID lv_name.
          ENDIF.
*
          CLEAR lt_messtab[].
          CALL TRANSACTION 'IDCP' WITH AUTHORITY-CHECK
                                  USING  bdcdata_tab OPTIONS FROM ls_options
                                  MESSAGES INTO lt_messtab.
*
          DELETE FROM DATABASE  indx(xy) ID lv_name.
          DELETE lt_messtab WHERE msgid EQ 'ICC_CN'.
          READ TABLE lt_messtab WITH KEY msgtyp = 'E' TRANSPORTING NO FIELDS.
          IF sy-subrc EQ 0.
            es_log-is_error = abap_true.
            LOOP AT lt_messtab ASSIGNING FIELD-SYMBOL(<ls_messtab>) WHERE  msgtyp = 'E'.
              APPEND INITIAL LINE TO es_log-messages ASSIGNING FIELD-SYMBOL(<ls_message>).
              MOVE : <ls_messtab>-msgnr  TO <ls_message>-number,
                     <ls_messtab>-msgtyp TO <ls_message>-type,
                     <ls_messtab>-msgid  TO <ls_message>-id,
                     <ls_messtab>-msgv1  TO <ls_message>-message_v1,
                     <ls_messtab>-msgv2  TO <ls_message>-message_v2,
                     <ls_messtab>-msgv3  TO <ls_message>-message_v3,
                     <ls_messtab>-msgv4  TO <ls_message>-message_v4.
              MESSAGE ID <ls_messtab>-msgid TYPE <ls_messtab>-msgtyp NUMBER <ls_messtab>-msgnr
                INTO <ls_message>-message
                WITH <ls_messtab>-msgv1 <ls_messtab>-msgv2 <ls_messtab>-msgv3 <ls_messtab>-msgv4.
            ENDLOOP.
          ELSE.
            es_log-is_error = abap_false.

            SELECT SINGLE FROM vbrk FIELDS xblnr
              WHERE vbeln = @is_data-vbeln_vf
              INTO @DATA(lv_xblnr).

            IF lv_xblnr = '0000000000000000' OR lv_xblnr IS INITIAL
                                             OR lv_xblnr = is_data-vbeln_vf.
              es_log-is_error = abap_true.
              APPEND INITIAL LINE TO es_log-messages ASSIGNING <ls_message>.
*             No se asigno folio a la factura &
              <ls_message>-type       = 'E'.
              <ls_message>-id         = 'ZSDH'.
              <ls_message>-number     = '003'.
              <ls_message>-message_v1 = is_data-vbeln_vf.
              MESSAGE e004 WITH is_data-vbeln_vf
                INTO <ls_message>-message.
            ELSE.
*             Factura enviada exitosamente
              es_log-is_error = abap_false.
              APPEND INITIAL LINE TO es_log-messages ASSIGNING <ls_message>.
*             Se guarda el folio de factura en la tabla de log
              <ls_message>-message_v1 = lv_xblnr.
            ENDIF.
          ENDIF.
        CATCH cx_sy_authorization_error ##NO_HANDLER.
      ENDTRY.

    ELSE.
      es_log-is_error = abap_true.
      APPEND INITIAL LINE TO es_log-messages ASSIGNING <ls_message>.
*     Pila & libro & no existe en la sociedad &
      <ls_message>-type       = 'E'.
      <ls_message>-id         = 'ZSDH'.
      <ls_message>-number     = '003'.
      <ls_message>-message_v1 = iv_lotno.
      <ls_message>-message_v2 = iv_bokno.
      <ls_message>-message_v3 = is_data-bukrs.
      MESSAGE e003 WITH iv_lotno iv_bokno is_data-bukrs
        INTO <ls_message>-message.
    ENDIF.

  ENDMETHOD.

  METHOD show_log.

    WRITE: 05 'Proceso:', 15 sy-repid,
          /05 'Fecha:',   15 sy-datum,
          /05 'Hora:',    15 sy-uzeit.
    SKIP 1.

    LOOP AT it_data ASSIGNING FIELD-SYMBOL(<ls_data>).
      WRITE: /002 <ls_data>-trxid,
              024 <ls_data>-kunnr,
              036  <ls_data>-name1,
              078 <ls_data>-vbeln_va,
              090 <ls_data>-vbeln_vf,
              102 <ls_data>-xblnr,
              120 <ls_data>-message.
    ENDLOOP.

*   Proceso finalizado
    MESSAGE i006.

  ENDMETHOD.

ENDCLASS.

CLASS lcl_cliente IMPLEMENTATION.

  METHOD extender_cliente_soc.
*   IMPORTING is_data    TYPE gty_data
*             is_cliente TYPE gty_cliente
*   EXPORTING et_log     TYPE gtt_log.
    DATA: ls_master_data           TYPE cmds_ei_main,
          ls_customers             TYPE cmds_ei_extern,
          ls_header                TYPE cmds_ei_header,
          ls_central_data          TYPE cmds_ei_central_data,
          ls_central               TYPE cmds_ei_cmd_central,
          ls_address               TYPE cvis_ei_address1,
          ls_postal                TYPE cvis_ei_1vl,
          ls_communication         TYPE cvis_ei_cvi_communication,
          ls_phone                 TYPE cvis_ei_phone_str,
          ls_text                  TYPE cvis_ei_cvis_text,
          ls_texts                 TYPE cvis_ei_text,
          ls_tline                 TYPE tline,
          ls_tax_ind               TYPE cmds_ei_cmd_tax_ind,
          ls_tax                   TYPE cmds_ei_tax_ind,
          ls_company_data          TYPE cmds_ei_cmd_company,
          ls_company               TYPE cmds_ei_company,
          ls_sales_data            TYPE cmds_ei_cmd_sales,
          ls_sales                 TYPE cmds_ei_sales,
          ls_functions             TYPE cmds_ei_functions,
          ls_master_data_correct   TYPE cmds_ei_main,
          ls_message_correct       TYPE cvis_message,
          ls_master_data_defective TYPE cmds_ei_main,
          ls_message_defective     TYPE cvis_message,
          ls_log                   TYPE gty_log.

    DATA: lt_customers TYPE cmds_ei_extern_t,
          lt_texts     TYPE cvis_ei_text_t,
          lt_company   TYPE cmds_ei_company_t,
          lt_tax_ind   TYPE cmds_ei_tax_ind_t,
          lt_sales     TYPE cmds_ei_sales_t,
          lt_functions TYPE cmds_ei_functions_t.

*   Cabecera datos mandante -------------------------------------------
*   Código de cliente
    ls_header-object_task = 'U'.
    ls_header-object_instance-kunnr = is_data-kunnr.
*   Se agrega el HEADER
    ls_customers-header = ls_header.

*   Datos CENTRAL -----------------------------------------------------
*   RUT
    ls_central-data-stcd1  = is_data-stcd1.
    ls_central-datax-stcd1 = abap_true.
*   Grupo de cuentas
    ls_central-data-ktokd  = is_data-ktokd.
    ls_central-datax-ktokd = abap_true.

*-- Se agregan datos CENTRAL A CENTRAL DATA
    ls_central_data-central   = ls_central.


*   Datos de direccion ------------------------------------------------
    ls_address-task = 'U'.

*   Nombre 1
    IF NOT is_data-name1 IS INITIAL.
      ls_postal-data-name  = is_data-name1.
      ls_postal-datax-name = abap_true.
    ENDIF.
*   Nombre 2
    IF NOT is_data-name2 IS INITIAL.
      ls_postal-data-name_2  = is_data-name2.
      ls_postal-datax-name_2 = abap_true.
    ENDIF.
*   Concepto busqueda
    IF NOT is_data-stcd1 IS INITIAL.
      ls_postal-data-sort1  = is_data-stcd1.
      ls_postal-datax-sort1 = abap_true.
    ENDIF.
*   Calle
    IF NOT is_data-street  IS INITIAL.
      ls_postal-data-street  = is_data-street.
      ls_postal-datax-street = abap_true.
    ENDIF.
*   Calle 2
    IF NOT is_data-str_suppl1 IS INITIAL.
      ls_postal-data-str_suppl1  = is_data-str_suppl1.
      ls_postal-datax-str_suppl1 = abap_true.
    ENDIF.
*   Número
    IF NOT is_data-house_num1 IS INITIAL.
      ls_postal-data-house_no  = is_data-house_num1.
      ls_postal-datax-house_no = abap_true.
    ENDIF.
*   Comuna
    IF NOT is_data-city2 IS INITIAL.
      ls_postal-data-district  = is_data-city2.
      ls_postal-datax-district = abap_true.
    ENDIF.
*   Ciudad
    IF NOT is_data-city1 IS INITIAL.
      ls_postal-data-city  = is_data-city1.
      ls_postal-datax-city = abap_true.
    ENDIF.
*   País
    IF NOT is_data-country IS INITIAL.
      ls_postal-data-country  = is_data-country.
      ls_postal-datax-country = abap_true.
    ENDIF.
*   Región
    IF NOT is_data-region IS INITIAL.
      ls_postal-data-region  = is_data-region.
      ls_postal-datax-region = abap_true.
    ENDIF.
*   Idioma
    ls_postal-data-langu  = sy-langu.
    ls_postal-datax-langu = abap_true.

*-- Se agregan datos POSTAL A ADDRESS
    ls_address-postal = ls_postal.
*
*   Datos de comunicación ---------------------------------------------
*   Teléfono 1
    IF NOT is_data-telephone IS INITIAL.
      ls_phone-contact-task = 'I'.
      ls_phone-contact-data-country    = 'CL'.
      ls_phone-contact-datax-country   = abap_true.
      ls_phone-contact-data-telephone  = is_data-telephone.
      ls_phone-contact-datax-telephone = abap_true.
      ls_phone-contact-data-r_3_user   = ' '.
      ls_phone-contact-datax-r_3_user  = abap_true.
      APPEND ls_phone TO ls_communication-phone-phone.
    ENDIF.

*   Movil
    IF NOT is_data-movil IS INITIAL.
      ls_phone-contact-task = 'I'.

      ls_phone-contact-data-country    = 'CL'.
      ls_phone-contact-datax-country   = abap_true.
      ls_phone-contact-data-telephone  = is_data-movil.
      ls_phone-contact-datax-telephone = abap_true.
      ls_phone-contact-data-r_3_user   = '3'.
      ls_phone-contact-datax-r_3_user  = abap_true.
      APPEND ls_phone TO ls_communication-phone-phone.
    ENDIF.

*-- Se agregan datos COMMUNICATION A ADDRESS
    ls_address-communication = ls_communication.

*-- Se agregan datos ADDRESS A CENTRAL DATA
    ls_central_data-address = ls_address.

*   Textos principales ------------------------------------------------
*   Giro
    IF NOT is_data-giro IS INITIAL.
      ls_texts-task = 'M'.
      ls_texts-data_key-text_id = 'Z003'.
      ls_texts-data_key-langu = sy-langu.

      ls_tline-tdformat = '*'.
      ls_tline-tdline = is_data-giro.
      APPEND ls_tline TO ls_texts-data.

*     Agregar textos
      APPEND ls_texts TO lt_texts.

*--   Se agregan datos TEXT A CENTRAL DATA
      ls_central_data-text-texts = lt_texts.
    ENDIF.

*   Identificadores de IVA --------------------------------------------
    IF NOT is_data-taxkd IS INITIAL.
      ls_tax-task = 'M'.

      ls_tax-data_key-aland = 'CL'.
      ls_tax-data_key-tatyp = 'MWST'.

      ls_tax-data-taxkd  = is_data-taxkd.
      ls_tax-datax-taxkd = abap_true.

      APPEND ls_tax TO lt_tax_ind.

*--   Se agregan datos TAX_IND A CENTRAL DATA
      ls_central_data-tax_ind-tax_ind = lt_tax_ind.
    ENDIF.

*   --- CENTRAL_DATA completo ----------------------------------------
    ls_customers-central_data = ls_central_data.

*   Datos sociedad ----------------------------------------------------
    ls_company-task = 'I'.
    ls_company-data_key = is_data-bukrs.
*   Cuenta asociada
    ls_company-data-akont  = is_data-akont.
    ls_company-datax-akont = abap_true.
*   Clave clasificación
    ls_company-data-zuawa  = is_data-zuawa.
    ls_company-datax-zuawa = abap_true.
*   Grupo de tesorer+ia
    ls_company-data-fdgrv  = is_data-fdgrv.
    ls_company-datax-fdgrv = abap_true.
*   Condición de pago
    ls_company-data-zterm  = is_data-zterm.
    ls_company-datax-zterm = abap_true.
*   Vía de pago
    ls_company-data-zwels  = is_data-zwels.
    ls_company-datax-zwels = abap_true.
*   Grabar historial pagos
    ls_company-data-xzver  = is_data-xzver.
    ls_company-datax-xzver = abap_true.

    APPEND ls_company TO lt_company.
*
*-- Se agregan datos COMPANY A COMPANY_DATA
    ls_company_data-company = lt_company.

*   --- COMPANY_DATA completo ----------------------------------------
    ls_customers-company_data = ls_company_data.

*   Datos de ventas ---------------------------------------------------
    ls_sales-task = 'I'.

    ls_sales-data_key-vkorg = is_data-vkorg.
    ls_sales-data_key-vtweg = is_data-vtweg.
    ls_sales-data_key-spart = is_data-spart.

    ls_sales-data-zterm  = is_data-zterm.
    ls_sales-datax-zterm = abap_true.
    ls_sales-data-ktgrd  = is_data-ktgrd.
    ls_sales-datax-ktgrd = abap_true.
    ls_sales-data-waers  = 'CLP'.
    ls_sales-datax-waers = abap_true.
    ls_sales-data-kalks  = '1'.
    ls_sales-datax-kalks = abap_true.

*   Funciones de interlocutor->Solicitante
    ls_functions-task = 'I'.
    ls_functions-data_key-parvw = 'AG'.
    ls_functions-data_key-parza = '001'.
    ls_functions-data-partner   = is_data-kunnr.
    ls_functions-datax-partner  = abap_true.
    APPEND ls_functions TO lt_functions.
*   Funciones de interlocutor->Destinatario de factura
    ls_functions-task = 'I'.
    ls_functions-data_key-parvw = 'RE'.
    ls_functions-data_key-parza = '002'.
    ls_functions-data-partner   = is_data-kunnr.
    ls_functions-datax-partner  = abap_true.
    APPEND ls_functions TO lt_functions.
*   Funciones de interlocutor->Responsable de pago
    ls_functions-task = 'I'.
    ls_functions-data_key-parvw = 'RG'.
    ls_functions-data_key-parza = '003'.
    ls_functions-data-partner   = is_data-kunnr.
    ls_functions-datax-partner  = abap_true.
    APPEND ls_functions TO lt_functions.
*   Funciones de interlocutor->Destinatario de mercancia
    ls_functions-task = 'I'.
    ls_functions-data_key-parvw = 'WE'.
    ls_functions-data_key-parza = '004'.
    ls_functions-data-partner   = is_data-kunnr.
    ls_functions-datax-partner  = abap_true.
    APPEND ls_functions TO lt_functions.

    ls_sales-functions-functions = lt_functions.

    APPEND ls_sales TO lt_sales.

*-- Se agregan datos SALES A SALES_DATA
    ls_sales_data-sales = lt_sales.

*   --- SALES_DATA completo ----------------------------------------
    ls_customers-sales_data = ls_sales_data.

*   Se agrega el cliente
    APPEND ls_customers TO lt_customers.

    ls_master_data-customers = lt_customers.

*   Llamado al método de creación
    CALL METHOD cmd_ei_api=>maintain_bapi
      EXPORTING
        iv_test_run              = ' '
        iv_collect_messages      = 'X'
        is_master_data           = ls_master_data
      IMPORTING
        es_master_data_correct   = ls_master_data_correct
        es_message_correct       = ls_message_correct
        es_master_data_defective = ls_master_data_defective
        es_message_defective     = ls_message_defective.

    IF ls_message_defective-is_error = abap_true.
      es_log = ls_message_defective.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
    ELSE.
      es_log = ls_message_defective.

      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          wait = 'X'.
      CLEAR: es_log.
    ENDIF.

  ENDMETHOD.

  METHOD crear_cliente.
*   IMPORTING is_data TYPE gty_data
*   EXPORTING et_log  TYPE gtt_log.
    DATA: ls_master_data           TYPE cmds_ei_main,
          ls_customers             TYPE cmds_ei_extern,
          ls_header                TYPE cmds_ei_header,
          ls_central_data          TYPE cmds_ei_central_data,
          ls_central               TYPE cmds_ei_cmd_central,
          ls_address               TYPE cvis_ei_address1,
          ls_postal                TYPE cvis_ei_1vl,
          ls_communication         TYPE cvis_ei_cvi_communication,
          ls_phone                 TYPE cvis_ei_phone_str,
          ls_text                  TYPE cvis_ei_cvis_text,
          ls_texts                 TYPE cvis_ei_text,
          ls_tline                 TYPE tline,
          ls_tax_ind               TYPE cmds_ei_cmd_tax_ind,
          ls_tax                   TYPE cmds_ei_tax_ind,
          ls_company_data          TYPE cmds_ei_cmd_company,
          ls_company               TYPE cmds_ei_company,
          ls_sales_data            TYPE cmds_ei_cmd_sales,
          ls_sales                 TYPE cmds_ei_sales,
          ls_functions             TYPE cmds_ei_functions,
          ls_master_data_correct   TYPE cmds_ei_main,
          ls_message_correct       TYPE cvis_message,
          ls_master_data_defective TYPE cmds_ei_main,
          ls_message_defective     TYPE cvis_message,
          ls_log                   TYPE gty_log.

    DATA: lt_customers TYPE cmds_ei_extern_t,
          lt_texts     TYPE cvis_ei_text_t,
          lt_company   TYPE cmds_ei_company_t,
          lt_tax_ind   TYPE cmds_ei_tax_ind_t,
          lt_sales     TYPE cmds_ei_sales_t,
          lt_functions TYPE cmds_ei_functions_t.

*   Cabecera datos mandante -------------------------------------------
*   Código de cliente
    ls_header-object_task = 'I'.
*   ls_header-object_instance-kunnr = is_data-stcd1.
*   Se agrega el HEADER
    ls_customers-header = ls_header.

*   Datos CENTRAL -----------------------------------------------------
*   RUT
    ls_central-data-stcd1  = is_data-stcd1.
    ls_central-datax-stcd1 = abap_true.
*   Grupo de cuentas
    ls_central-data-ktokd  = is_data-ktokd.
    ls_central-datax-ktokd = abap_true.

*-- Se agregan datos CENTRAL A CENTRAL DATA
    ls_central_data-central   = ls_central.


*   Datos de direccion ------------------------------------------------
    ls_address-task = 'I'.

*   Nombre 1
    ls_postal-data-name  = is_data-name1.
    ls_postal-datax-name = abap_true.
*   Nombre 2
    ls_postal-data-name_2  = is_data-name2.
    ls_postal-datax-name_2 = abap_true.
*   Concepto bpusqueda
    ls_postal-data-sort1  = is_data-stcd1.
    ls_postal-datax-sort1 = abap_true.
*   Calle
    ls_postal-data-street  = is_data-street.
    ls_postal-datax-street = abap_true.
*   Calle 2
    ls_postal-data-str_suppl1  = is_data-str_suppl1.
    ls_postal-datax-str_suppl1 = abap_true.
*   Número
    ls_postal-data-house_no  = is_data-house_num1.
    ls_postal-datax-house_no = abap_true.
*   Comuna
    ls_postal-data-district  = is_data-city2.
    ls_postal-datax-district = abap_true.
*   Ciudad
    ls_postal-data-city  = is_data-city1.
    ls_postal-datax-city = abap_true.
*   País
    ls_postal-data-country  = is_data-country.
    ls_postal-datax-country = abap_true.
*   Región
    ls_postal-data-region  = is_data-region.
    ls_postal-datax-region = abap_true.
*   Idioma
    ls_postal-data-langu  = sy-langu.
    ls_postal-datax-langu = abap_true.

*-- Se agregan datos POSTAL A ADDRESS
    ls_address-postal = ls_postal.
*
*   Datos de comunicación ---------------------------------------------
*   Teléfono 1
    IF NOT is_data-telephone IS INITIAL.
      ls_phone-contact-task = 'I'.
      ls_phone-contact-data-country    = 'CL'.
      ls_phone-contact-datax-country   = abap_true.
      ls_phone-contact-data-telephone  = is_data-telephone.
      ls_phone-contact-datax-telephone = abap_true.
      ls_phone-contact-data-r_3_user   = ' '.
      ls_phone-contact-datax-r_3_user  = abap_true.
      APPEND ls_phone TO ls_communication-phone-phone.
    ENDIF.

*   Movil
    IF NOT is_data-movil IS INITIAL.
      ls_phone-contact-task = 'I'.

      ls_phone-contact-data-country    = 'CL'.
      ls_phone-contact-datax-country   = abap_true.
      ls_phone-contact-data-telephone  = is_data-movil.
      ls_phone-contact-datax-telephone = abap_true.
      ls_phone-contact-data-r_3_user   = '3'.
      ls_phone-contact-datax-r_3_user  = abap_true.
      APPEND ls_phone TO ls_communication-phone-phone.
    ENDIF.

*-- Se agregan datos COMMUNICATION A ADDRESS
    ls_address-communication = ls_communication.
*    ls_central_data-address = ls_address1.

*-- Se agregan datos ADDRESS A CENTRAL DATA
    ls_central_data-address = ls_address.

*   Textos principales ------------------------------------------------
*   Giro
    ls_texts-task = 'M'.
    ls_texts-data_key-text_id = 'Z003'.
    ls_texts-data_key-langu = sy-langu.

    ls_tline-tdformat = '*'.
    ls_tline-tdline = is_data-giro.
    APPEND ls_tline TO ls_texts-data.

*   Agregar textos
    APPEND ls_texts TO lt_texts.

*-- Se agregan datos TEXT A CENTRAL DATA
    ls_central_data-text-texts = lt_texts.
*
*   Identificadores de IVA --------------------------------------------
    ls_tax-task = 'I'.

    ls_tax-data_key-aland = 'CL'.
    ls_tax-data_key-tatyp = 'MWST'.

    ls_tax-data-taxkd  = is_data-taxkd.
    ls_tax-datax-taxkd = abap_true.

    APPEND ls_tax TO lt_tax_ind.

*-- Se agregan datos TAX_IND A CENTRAL DATA
    ls_central_data-tax_ind-tax_ind = lt_tax_ind.

*   --- CENTRAL_DATA completo ----------------------------------------
    ls_customers-central_data = ls_central_data.

*   Datos sociedad ----------------------------------------------------
    ls_company-task = 'I'.
    ls_company-data_key = is_data-bukrs.
*   Cuenta asociada
    ls_company-data-akont  = is_data-akont.
    ls_company-datax-akont = abap_true.
*   Clave clasificación
    ls_company-data-zuawa  = is_data-zuawa.
    ls_company-datax-zuawa = abap_true.
*   Grupo de tesorer+ia
    ls_company-data-fdgrv  = is_data-fdgrv.
    ls_company-datax-fdgrv = abap_true.
*   Condición de pago
    ls_company-data-zterm  = is_data-zterm.
    ls_company-datax-zterm = abap_true.
*   Vía de pago
    ls_company-data-zwels  = is_data-zwels.
    ls_company-datax-zwels = abap_true.
*   Grabar historial pagos
    ls_company-data-xzver  = is_data-xzver.
    ls_company-datax-xzver = abap_true.

    APPEND ls_company TO lt_company.
*
*-- Se agregan datos COMPANY A COMPANY_DATA
    ls_company_data-company = lt_company.

*   --- COMPANY_DATA completo ----------------------------------------
    ls_customers-company_data = ls_company_data.

*   Datos de ventas ---------------------------------------------------
    ls_sales-task = 'I'.

    ls_sales-data_key-vkorg = is_data-vkorg.
    ls_sales-data_key-vtweg = is_data-vtweg.
    ls_sales-data_key-spart = is_data-spart.

    ls_sales-data-zterm  = is_data-zterm.
    ls_sales-datax-zterm = abap_true.
    ls_sales-data-ktgrd  = is_data-ktgrd.
    ls_sales-datax-ktgrd = abap_true.
    ls_sales-data-waers  = 'CLP'.
    ls_sales-datax-waers = abap_true.
    ls_sales-data-kalks  = '1'.
    ls_sales-datax-kalks = abap_true.

*   Funciones de interlocutor->Solicitante
    ls_functions-task = 'I'.
    ls_functions-data_key-parvw = 'AG'.
    ls_functions-data_key-parza = '001'.
*   ls_functions-data-partner   = is_data-stcd1.
    ls_functions-datax-partner  = abap_true.
    APPEND ls_functions TO lt_functions.
*   Funciones de interlocutor->Destinatario de factura
    ls_functions-task = 'I'.
    ls_functions-data_key-parvw = 'RE'.
    ls_functions-data_key-parza = '002'.
*   ls_functions-data-partner   = is_data-stcd1.
    ls_functions-datax-partner  = abap_true.
    APPEND ls_functions TO lt_functions.
*   Funciones de interlocutor->Responsable de pago
    ls_functions-task = 'I'.
    ls_functions-data_key-parvw = 'RG'.
    ls_functions-data_key-parza = '003'.
*   ls_functions-data-partner   = is_data-stcd1.
    ls_functions-datax-partner  = abap_true.
    APPEND ls_functions TO lt_functions.
*   Funciones de interlocutor->Destinatario de mercancia
    ls_functions-task = 'I'.
    ls_functions-data_key-parvw = 'WE'.
    ls_functions-data_key-parza = '004'.
*   ls_functions-data-partner   = is_data-stcd1.
    ls_functions-datax-partner  = abap_true.
    APPEND ls_functions TO lt_functions.

    ls_sales-functions-functions = lt_functions.

    APPEND ls_sales TO lt_sales.

*-- Se agregan datos SALES A SALES_DATA
    ls_sales_data-sales = lt_sales.

*   --- SALES_DATA completo ----------------------------------------
    ls_customers-sales_data = ls_sales_data.

*   Se agrega el cliente
    APPEND ls_customers TO lt_customers.

    ls_master_data-customers = lt_customers.

*   Llamado al método de creación
    CALL METHOD cmd_ei_api=>maintain_bapi
      EXPORTING
        iv_test_run              = ' '
        iv_collect_messages      = 'X'
        is_master_data           = ls_master_data
      IMPORTING
        es_master_data_correct   = ls_master_data_correct
        es_message_correct       = ls_message_correct
        es_master_data_defective = ls_master_data_defective
        es_message_defective     = ls_message_defective.

    IF ls_message_defective-is_error = abap_true.
      es_log = ls_message_defective.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
    ELSE.
      CLEAR: ls_message_defective-messages.
      READ TABLE ls_master_data_correct-customers ASSIGNING FIELD-SYMBOL(<ls_customer>) INDEX 1.
      IF sy-subrc = 0.
        APPEND INITIAL LINE TO ls_message_defective-messages ASSIGNING FIELD-SYMBOL(<fs_message>).
        <fs_message>-message_v1 = <ls_customer>-header-object_instance-kunnr.
      ENDIF.

      es_log = ls_message_defective.

      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          wait = 'X'.
    ENDIF.

  ENDMETHOD.

  METHOD extender_cliente_av.
*   IMPORTING is_data    TYPE gty_data
*             is_cliente TYPE gty_cliente
*   EXPORTING et_log     TYPE gtt_log.
    DATA: ls_master_data           TYPE cmds_ei_main,
          ls_customers             TYPE cmds_ei_extern,
          ls_header                TYPE cmds_ei_header,
          ls_central_data          TYPE cmds_ei_central_data,
          ls_central               TYPE cmds_ei_cmd_central,
          ls_address               TYPE cvis_ei_address1,
          ls_postal                TYPE cvis_ei_1vl,
          ls_communication         TYPE cvis_ei_cvi_communication,
          ls_phone                 TYPE cvis_ei_phone_str,
          ls_text                  TYPE cvis_ei_cvis_text,
          ls_texts                 TYPE cvis_ei_text,
          ls_tline                 TYPE tline,
          ls_tax_ind               TYPE cmds_ei_cmd_tax_ind,
          ls_tax                   TYPE cmds_ei_tax_ind,
          ls_company_data          TYPE cmds_ei_cmd_company,
          ls_company               TYPE cmds_ei_company,
          ls_sales_data            TYPE cmds_ei_cmd_sales,
          ls_sales                 TYPE cmds_ei_sales,
          ls_functions             TYPE cmds_ei_functions,
          ls_master_data_correct   TYPE cmds_ei_main,
          ls_message_correct       TYPE cvis_message,
          ls_master_data_defective TYPE cmds_ei_main,
          ls_message_defective     TYPE cvis_message,
          ls_log                   TYPE gty_log.

    DATA: lt_customers TYPE cmds_ei_extern_t,
          lt_texts     TYPE cvis_ei_text_t,
          lt_company   TYPE cmds_ei_company_t,
          lt_tax_ind   TYPE cmds_ei_tax_ind_t,
          lt_sales     TYPE cmds_ei_sales_t,
          lt_functions TYPE cmds_ei_functions_t.

*   Cabecera datos mandante -------------------------------------------
*   Código de cliente
    ls_header-object_task = 'U'.
    ls_header-object_instance-kunnr = is_data-kunnr.
*   Se agrega el HEADER
    ls_customers-header = ls_header.

*   Datos CENTRAL -----------------------------------------------------
*   RUT
*    ls_central-data-stcd1  = is_data-stcd1.
*    ls_central-datax-stcd1 = abap_true.
**   Grupo de cuentas
*    ls_central-data-ktokd  = is_data-ktokd.
*    ls_central-datax-ktokd = abap_true.
*
**-- Se agregan datos CENTRAL A CENTRAL DATA
*    ls_central_data-central   = ls_central.


*   Datos de direccion ------------------------------------------------
*    ls_address-task = 'U'.
*
**   Nombre 1
*    IF NOT is_data-name1 IS INITIAL.
*      ls_postal-data-name  = is_data-name1.
*      ls_postal-datax-name = abap_true.
*    ENDIF.
**   Nombre 2
*    IF NOT is_data-name2 IS INITIAL.
*      ls_postal-data-name_2  = is_data-name2.
*      ls_postal-datax-name_2 = abap_true.
*    ENDIF.
**   Concepto busqueda
*    IF NOT is_data-stcd1 IS INITIAL.
*      ls_postal-data-sort1  = is_data-stcd1.
*      ls_postal-datax-sort1 = abap_true.
*    ENDIF.
**   Calle
*    IF NOT is_data-street  IS INITIAL.
*      ls_postal-data-street  = is_data-street.
*      ls_postal-datax-street = abap_true.
*    ENDIF.
**   Calle 2
*    IF NOT is_data-str_suppl1 IS INITIAL.
*      ls_postal-data-str_suppl1  = is_data-str_suppl1.
*      ls_postal-datax-str_suppl1 = abap_true.
*    ENDIF.
**   Número
*    IF NOT is_data-house_num1 IS INITIAL.
*      ls_postal-data-house_no  = is_data-house_num1.
*      ls_postal-datax-house_no = abap_true.
*    ENDIF.
**   Comuna
*    IF NOT is_data-city2 IS INITIAL.
*      ls_postal-data-district  = is_data-city2.
*      ls_postal-datax-district = abap_true.
*    ENDIF.
**   Ciudad
*    IF NOT is_data-city1 IS INITIAL.
*      ls_postal-data-city  = is_data-city1.
*      ls_postal-datax-city = abap_true.
*    ENDIF.
**   País
*    IF NOT is_data-country IS INITIAL.
*      ls_postal-data-country  = is_data-country.
*      ls_postal-datax-country = abap_true.
*    ENDIF.
**   Región
*    IF NOT is_data-region IS INITIAL.
*      ls_postal-data-region  = is_data-region.
*      ls_postal-datax-region = abap_true.
*    ENDIF.
**   Idioma
*    ls_postal-data-langu  = sy-langu.
*    ls_postal-datax-langu = abap_true.
*
**-- Se agregan datos POSTAL A ADDRESS
*    ls_address-postal = ls_postal.
**
**   Datos de comunicación ---------------------------------------------
**   Teléfono 1
*    IF NOT is_data-telephone IS INITIAL.
*      ls_phone-contact-task = 'I'.
*      ls_phone-contact-data-country    = 'CL'.
*      ls_phone-contact-datax-country   = abap_true.
*      ls_phone-contact-data-telephone  = is_data-telephone.
*      ls_phone-contact-datax-telephone = abap_true.
*      ls_phone-contact-data-r_3_user   = ' '.
*      ls_phone-contact-datax-r_3_user  = abap_true.
*      APPEND ls_phone TO ls_communication-phone-phone.
*    ENDIF.
*
**   Movil
*    IF NOT is_data-movil IS INITIAL.
*      ls_phone-contact-task = 'I'.
*
*      ls_phone-contact-data-country    = 'CL'.
*      ls_phone-contact-datax-country   = abap_true.
*      ls_phone-contact-data-telephone  = is_data-movil.
*      ls_phone-contact-datax-telephone = abap_true.
*      ls_phone-contact-data-r_3_user   = '3'.
*      ls_phone-contact-datax-r_3_user  = abap_true.
*      APPEND ls_phone TO ls_communication-phone-phone.
*    ENDIF.
*
**-- Se agregan datos COMMUNICATION A ADDRESS
*    ls_address-communication = ls_communication.
*
**-- Se agregan datos ADDRESS A CENTRAL DATA
*    ls_central_data-address = ls_address.
*
**   Textos principales ------------------------------------------------
**   Giro
*    IF NOT is_data-giro IS INITIAL.
*      ls_texts-task = 'M'.
*      ls_texts-data_key-text_id = 'Z003'.
*      ls_texts-data_key-langu = sy-langu.
*
*      ls_tline-tdformat = '*'.
*      ls_tline-tdline = is_data-giro.
*      APPEND ls_tline TO ls_texts-data.
*
**     Agregar textos
*      APPEND ls_texts TO lt_texts.
*
**--   Se agregan datos TEXT A CENTRAL DATA
*      ls_central_data-text-texts = lt_texts.
*    ENDIF.

*   Identificadores de IVA --------------------------------------------
    IF NOT is_data-taxkd IS INITIAL.
      ls_tax-task = 'U'.

      ls_tax-data_key-aland = 'CL'.
      ls_tax-data_key-tatyp = 'MWST'.

      ls_tax-data-taxkd  = is_data-taxkd.
      ls_tax-datax-taxkd = abap_true.

      APPEND ls_tax TO lt_tax_ind.

*--   Se agregan datos TAX_IND A CENTRAL DATA
      ls_central_data-tax_ind-tax_ind = lt_tax_ind.
    ENDIF.

*   --- CENTRAL_DATA completo ----------------------------------------
    ls_customers-central_data = ls_central_data.

*   Datos de ventas ---------------------------------------------------
    ls_sales-task = 'I'.

    ls_sales-data_key-vkorg = is_data-vkorg.
    ls_sales-data_key-vtweg = is_data-vtweg.
    ls_sales-data_key-spart = is_data-spart.

    ls_sales-data-zterm  = is_data-zterm.
    ls_sales-datax-zterm = abap_true.
    ls_sales-data-ktgrd  = is_data-ktgrd.
    ls_sales-datax-ktgrd = abap_true.
    ls_sales-data-waers  = 'CLP'.
    ls_sales-datax-waers = abap_true.
    ls_sales-data-kalks  = '1'.
    ls_sales-datax-kalks = abap_true.

*   Funciones de interlocutor->Solicitante
    ls_functions-task = 'I'.
    ls_functions-data_key-parvw = 'AG'.
    ls_functions-data_key-parza = '001'.
    ls_functions-data-partner   = is_data-kunnr.
    ls_functions-datax-partner  = abap_true.
    APPEND ls_functions TO lt_functions.
*   Funciones de interlocutor->Destinatario de factura
    ls_functions-task = 'I'.
    ls_functions-data_key-parvw = 'RE'.
    ls_functions-data_key-parza = '002'.
    ls_functions-data-partner   = is_data-kunnr.
    ls_functions-datax-partner  = abap_true.
    APPEND ls_functions TO lt_functions.
*   Funciones de interlocutor->Responsable de pago
    ls_functions-task = 'I'.
    ls_functions-data_key-parvw = 'RG'.
    ls_functions-data_key-parza = '003'.
    ls_functions-data-partner   = is_data-kunnr.
    ls_functions-datax-partner  = abap_true.
    APPEND ls_functions TO lt_functions.
*   Funciones de interlocutor->Destinatario de mercancia
    ls_functions-task = 'I'.
    ls_functions-data_key-parvw = 'WE'.
    ls_functions-data_key-parza = '004'.
    ls_functions-data-partner   = is_data-kunnr.
    ls_functions-datax-partner  = abap_true.
    APPEND ls_functions TO lt_functions.

    ls_sales-functions-functions = lt_functions.

    APPEND ls_sales TO lt_sales.

*-- Se agregan datos SALES A SALES_DATA
    ls_sales_data-sales = lt_sales.

*   --- SALES_DATA completo ----------------------------------------
    ls_customers-sales_data = ls_sales_data.

*   Se agrega el cliente
    APPEND ls_customers TO lt_customers.

    ls_master_data-customers = lt_customers.

*   Llamado al método de creación
    CALL METHOD cmd_ei_api=>maintain_bapi
      EXPORTING
        iv_test_run              = ' '
        iv_collect_messages      = 'X'
        is_master_data           = ls_master_data
      IMPORTING
        es_master_data_correct   = ls_master_data_correct
        es_message_correct       = ls_message_correct
        es_master_data_defective = ls_master_data_defective
        es_message_defective     = ls_message_defective.

    IF ls_message_defective-is_error = abap_true.
      es_log = ls_message_defective.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
    ELSE.
      es_log = ls_message_defective.

      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          wait = 'X'.
      CLEAR: es_log.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
