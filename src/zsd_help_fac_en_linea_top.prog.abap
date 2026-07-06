*&---------------------------------------------------------------------*
*&  Include           ZSD_HELP_FAC_EN_LINEA_TOP
*&---------------------------------------------------------------------*
CONSTANTS: gc_tcode TYPE sytcode VALUE 'ZFACENLINEA'.

TYPES: BEGIN OF gty_cliente,
         kunnr TYPE kunnr,
         bukrs TYPE bukrs,
         stcd1 TYPE stcd1,
       END OF gty_cliente.

TYPES: gty_data TYPE zst_sd_faenli_data,
       gty_log  TYPE cvis_message.

TYPES: gtt_data    TYPE STANDARD TABLE OF gty_data,
       gtt_log     TYPE STANDARD TABLE OF gty_log,
       gtt_cliente TYPE STANDARD TABLE OF gty_cliente.

DATA: gt_data TYPE gtt_data,
      gt_log  TYPE gtt_log.

DATA: gv_rc TYPE sysubrc.
