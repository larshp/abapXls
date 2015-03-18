REPORT zfoo.

START-OF-SELECTION.
  PERFORM run.

FORM run.

  DATA: lv_xstr TYPE xstring.


  PERFORM read_file CHANGING lv_xstr.
  PERFORM parse_cdh USING lv_xstr.
  PERFORM parse_sat USING lv_xstr.
  PERFORM parse_directory USING lv_xstr.

ENDFORM.

FORM parse_directory USING lv_xstr TYPE xstring.

  DATA: lv_dir TYPE x LENGTH 1024.


  lv_dir = lv_xstr+1024(1024).

* todo

ENDFORM.

FORM parse_cdh USING pv_xstr TYPE xstring.

  DATA: lv_cdh TYPE x LENGTH 512.

  DATA: lv_sector_size  TYPE x LENGTH 2,
        lv_sat_sectors  TYPE x LENGTH 4,
        lv_secid_dir    TYPE x LENGTH 4,
        lv_secid_ssat   TYPE x LENGTH 4,
        lv_ssat_sectors TYPE x LENGTH 4,
        lv_secid_msat   TYPE x LENGTH 4,
        lv_msat_sectors TYPE x LENGTH 4,
        lv_min          TYPE x LENGTH 4,
        lv_short_size   TYPE x LENGTH 2.


  lv_cdh = pv_xstr.

  IF lv_cdh(8) <> 'D0CF11E0A1B11AE1'.
* unexpected compound document file identifier
    BREAK-POINT.
    RETURN.
  ENDIF.
  lv_cdh = lv_cdh+8.

  lv_cdh = lv_cdh+16.
  lv_cdh = lv_cdh+4.

  IF lv_cdh(2) <> 'FEFF'.
* unexpected byte order
    BREAK-POINT.
    RETURN.
  ENDIF.
  lv_cdh = lv_cdh+2.

  lv_sector_size = lv_cdh(2).
  lv_cdh = lv_cdh+2.
  lv_short_size = lv_cdh(2).
  lv_cdh = lv_cdh+2.

  lv_cdh = lv_cdh+10.

  lv_sat_sectors = lv_cdh(4).
  IF lv_sat_sectors <> '01000000'.
* not implemented
    BREAK-POINT.
  ENDIF.
  lv_cdh = lv_cdh+4.

  lv_secid_dir = lv_cdh(4).
  WRITE: / 'Directory SecID:', lv_secid_dir.
  lv_cdh = lv_cdh+4.

  lv_cdh = lv_cdh+4.

  lv_min = lv_cdh(4).
  lv_cdh = lv_cdh+4.

  lv_secid_ssat = lv_cdh(4).
  lv_cdh = lv_cdh+4.

  lv_ssat_sectors = lv_cdh(4).
  lv_cdh = lv_cdh+4.

  lv_secid_msat = lv_cdh(4).
  IF lv_secid_msat <> 'FEFFFFFF'.
* not implemented
    BREAK-POINT.
  ENDIF.
  lv_cdh = lv_cdh+4.

  lv_msat_sectors = lv_cdh(4).
  IF lv_msat_sectors <> '00000000'.
* not implemented
    BREAK-POINT.
  ENDIF.
  lv_cdh = lv_cdh+4.

  WRITE: /.

ENDFORM.

FORM parse_sat USING pv_xstr TYPE xstring.

  DATA: lv_sat    TYPE x LENGTH 512,
        lv_index  TYPE i,
        lv_sector TYPE x LENGTH 4.


  lv_sat = pv_xstr+512.

  DO 128 TIMES.
    lv_index = sy-index - 1.
    lv_sector = lv_sat(4).
    lv_sat = lv_sat+4.
    WRITE: / 'Sector', lv_index, ':', lv_sector.
    CASE lv_sector.
      WHEN 'FFFFFFFF'.
        WRITE: 'Free'.
      WHEN 'FEFFFFFF'.
        WRITE: 'End of chain'.
      WHEN 'FDFFFFFF'.
        WRITE: 'SAT SecID'.
      WHEN 'FCFFFFFF'.
        WRITE: 'MSAT SecID'.
    ENDCASE.
  ENDDO.

ENDFORM.

FORM read_file CHANGING pv_xstr TYPE xstring.

  DATA: lt_file TYPE sbdst_content,
        lv_len  TYPE i.

  FIELD-SYMBOLS: <ls_file> LIKE LINE OF lt_file.


  cl_gui_frontend_services=>gui_upload(
    EXPORTING
      filename                = '2003.xls'
      filetype                = 'BIN'
    IMPORTING
      filelength              = lv_len
    CHANGING
      data_tab                = lt_file
    EXCEPTIONS
      file_open_error         = 1
      file_read_error         = 2
      no_batch                = 3
      gui_refuse_filetransfer = 4
      invalid_type            = 5
      no_authority            = 6
      unknown_error           = 7
      bad_data_format         = 8
      header_not_allowed      = 9
      separator_not_allowed   = 10
      header_too_long         = 11
      unknown_dp_error        = 12
      access_denied           = 13
      dp_out_of_memory        = 14
      disk_full               = 15
      dp_timeout              = 16
      not_supported_by_gui    = 17
      error_no_gui            = 18
      OTHERS                  = 19 ).
  IF sy-subrc <> 0.
    BREAK-POINT.
  ENDIF.

  LOOP AT lt_file ASSIGNING <ls_file>.
    CONCATENATE pv_xstr <ls_file>-line INTO pv_xstr IN BYTE MODE.
  ENDLOOP.
  pv_xstr = pv_xstr(lv_len).

ENDFORM.
