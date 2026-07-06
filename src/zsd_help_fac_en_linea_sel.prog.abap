*&---------------------------------------------------------------------*
*&  Include           ZSD_HELP_FAC_EN_LINEA_SEL
*&---------------------------------------------------------------------*
*--------------------------------------------------------------------*
*                        SELECTION-SCREEN
*--------------------------------------------------------------------*
  SELECTION-SCREEN: BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-t01.
  PARAMETERS: p_bukrs TYPE bukrs OBLIGATORY.
  SELECTION-SCREEN: END OF BLOCK b1.

*--------------------------------------------------------------------*
*                      INITIALIZATION
*--------------------------------------------------------------------*
  INITIALIZATION.

    AUTHORITY-CHECK OBJECT 'S_TCODE'
              ID 'TCD' FIELD gc_tcode.

    IF sy-subrc <> 0.
*     Falta autorización para transacción &
      MESSAGE e077(s#) WITH gc_tcode.
      EXIT.
    ENDIF.

*--------------------------------------------------------------------*
*                   AT SELECTION-SCREEN
*--------------------------------------------------------------------*
  AT SELECTION-SCREEN.

    SELECT SINGLE FROM t001 FIELDS butxt
      WHERE bukrs = @p_bukrs
      INTO @DATA(lv_butxt).

    IF sy-subrc <> 0.
*     Ingrese una sociedad válida
      MESSAGE e001.
    ELSE.
      AUTHORITY-CHECK OBJECT 'F_BKPF_BUK'
            ID 'BUKRS' FIELD p_bukrs
            ID 'ACTVT' FIELD '03'.

      IF sy-subrc <> 0.
*       Ud. carece de autorización para la sociedad &.
        MESSAGE e460(f5) WITH p_bukrs.
      ENDIF.
    ENDIF.
