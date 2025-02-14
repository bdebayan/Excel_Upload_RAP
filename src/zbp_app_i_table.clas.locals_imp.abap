CLASS lhc_app DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    TYPES: BEGIN OF ts_excel,
             country TYPE string,
             ranking TYPE string,
             text    TYPE string,
           END OF ts_excel.
    TYPES tt_excel TYPE STANDARD TABLE OF ts_excel WITH EMPTY KEY.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR app RESULT result.

    METHODS LoadExcelContent FOR MODIFY
      IMPORTING keys FOR ACTION app~LoadExcelContent RESULT result.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR app RESULT result.

    METHODS convert_excel_file_to_table
      IMPORTING id_stream        TYPE xstring
      RETURNING VALUE(rt_result) TYPE tt_excel
      RAISING   zcx_drp_excel_error.

ENDCLASS.

CLASS lhc_app IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD LoadExcelContent.
    DATA lt_app_modify       TYPE TABLE FOR UPDATE zapp_i_table\\app.
    DATA lt_countries_create TYPE TABLE FOR CREATE zapp_i_table\_currency.
    DATA lt_countries_modify TYPE TABLE FOR UPDATE zapp_i_table\\Country.

    READ ENTITIES OF zapp_i_table IN LOCAL MODE
         ENTITY app FIELDS ( AppId ExcelAttachment ) WITH CORRESPONDING #( keys )
         RESULT DATA(lt_attachement)
         ENTITY app BY \_currency ALL FIELDS WITH CORRESPONDING #( keys )
         RESULT DATA(lt_countries).
    TRY.
        DATA(ls_key) = keys[ 1 ].
        DATA(ls_attachement) = lt_attachement[ 1 ].
      CATCH cx_sy_itab_line_not_found.
        INSERT new_message( id       = 'ZBS_DEMO_RAP_PATTERN'
                            number   = '003'
                            severity = if_abap_behv_message=>severity-error )
               INTO TABLE reported-%other.
        RETURN.
    ENDTRY.

    TRY.
        DATA(lt_excel) = convert_excel_file_to_table( ls_attachement-ExcelAttachment ).
      CATCH zcx_drp_excel_error INTO DATA(lo_excel_error).
        INSERT lo_excel_error INTO TABLE reported-%other.
        RETURN.
    ENDTRY.

    INSERT new_message( id       = 'ZBS_DEMO_RAP_PATTERN'
                        number   = '005'
                        severity = if_abap_behv_message=>severity-success
                        v1       = lines( lt_excel ) )
           INTO TABLE reported-%other.

    IF ls_key-%param-TestRun = abap_true.
      INSERT new_message( id       = 'ZBS_DEMO_RAP_PATTERN'
                          number   = '004'
                          severity = if_abap_behv_message=>severity-warning )
             INTO TABLE reported-%other.
      RETURN.
    ENDIF.

    INSERT VALUE #( %tky                     = ls_attachement-%tky
                    ExcelAttachment          = ''
                    excelmimetype            = ''
                    excelfilename            = ''
                    %control-ExcelAttachment = if_abap_behv=>mk-on
                    %control-excelmimetype   = if_abap_behv=>mk-on
                    %control-excelfilename   = if_abap_behv=>mk-on )
           INTO TABLE lt_app_modify.

    INSERT VALUE #( appid = ls_attachement-AppId )
           INTO TABLE lt_countries_create REFERENCE INTO DATA(lr_new).

    LOOP AT lt_excel INTO DATA(ls_excel).
      TRY.
          DATA(ls_country) = lt_countries[ Country = ls_excel-country ].
          INSERT VALUE #( appid            = ls_attachement-AppId
                          country          = ls_country-Country
                          ranking          = ls_excel-ranking
                          text             = ls_excel-text
                          %control-ranking = if_abap_behv=>mk-on
                          %control-text    = if_abap_behv=>mk-on   )
                 INTO TABLE lt_countries_modify.

        CATCH cx_sy_itab_line_not_found.
          INSERT VALUE #( %cid             = xco_cp=>uuid( )->value
                          appid            = ls_attachement-AppId
                          country          = ls_excel-country
                          ranking          = ls_excel-ranking
                          text             = ls_excel-text
                          %control-country = if_abap_behv=>mk-on
                          %control-ranking = if_abap_behv=>mk-on
                          %control-text    = if_abap_behv=>mk-on )
                 INTO TABLE lr_new->%target.
      ENDTRY.
    ENDLOOP.
    MODIFY ENTITIES OF zapp_i_table IN LOCAL MODE
           ENTITY app UPDATE FROM lt_app_modify
           ENTITY country UPDATE FROM lt_countries_modify
           ENTITY app CREATE BY \_currency FROM lt_countries_create
            " TODO: variable is assigned but never used (ABAP cleaner)
           FAILED   FINAL(fail_mod2)
           " TODO: variable is assigned but never used (ABAP cleaner)
           REPORTED FINAL(rep_mod2)
           MAPPED   FINAL(map_mod2).
    mapped-app     = VALUE #( ( AppId = ls_attachement-AppId ) ).
    mapped-country = map_mod2-country.

    READ ENTITIES OF zapp_i_table IN LOCAL MODE
         ENTITY app FIELDS ( AppId ExcelAttachment ) WITH CORRESPONDING #( keys )
         " TODO: variable is assigned but never used (ABAP cleaner)
         RESULT DATA(lt_attachement1)
         ENTITY app BY \_currency ALL FIELDS WITH CORRESPONDING #( keys )
         RESULT DATA(lt_countries1).

    READ ENTITIES OF zapp_i_table IN LOCAL MODE
         ENTITY app
         ALL FIELDS WITH
         CORRESPONDING #( keys )
         " TODO: variable is assigned but never used (ABAP cleaner)
         RESULT DATA(lt_data).

    result = VALUE #( FOR ls_data IN lt_data
                      ( %tky   = ls_data-%tky
                        %param = ls_data ) ).

    INSERT new_message( id       = 'ZBS_DEMO_RAP_PATTERN'
                        number   = '007'
                        severity = if_abap_behv_message=>severity-success
                        v1       = lines( lt_countries_create[ 1 ]-%target ) )
           INTO TABLE reported-%other.

    INSERT new_message( id       = 'ZBS_DEMO_RAP_PATTERN'
                        number   = '006'
                        severity = if_abap_behv_message=>severity-success
                        v1       = lines( lt_countries_modify ) )
           INTO TABLE reported-%other.
  ENDMETHOD.

  METHOD convert_excel_file_to_table.
    IF id_stream IS INITIAL.
      RAISE EXCEPTION NEW zcx_drp_excel_error( textid = VALUE #( msgid = 'ZBS_DEMO_RAP_PATTERN'
                                                                 msgno = '001' ) ).
    ENDIF.

    DATA(lo_sheet) = xco_cp_xlsx=>document->for_file_content( id_stream
      )->read_access( )->get_workbook(
      )->worksheet->at_position( 1 ).

    IF NOT lo_sheet->exists( ).
      RAISE EXCEPTION NEW zcx_drp_excel_error( textid = VALUE #( msgid = 'ZBS_DEMO_RAP_PATTERN'
                                                                 msgno = '002' ) ).
    ENDIF.

    DATA(lo_pattern) = xco_cp_xlsx_selection=>pattern_builder->simple_from_to(
      )->from_column( xco_cp_xlsx=>coordinate->for_alphabetic_value( 'A' )
      )->from_row( xco_cp_xlsx=>coordinate->for_numeric_value( 2 )
      )->get_pattern( ).

    lo_sheet->select( lo_pattern
      )->row_stream(
      )->operation->write_to( REF #( rt_result )
      )->set_value_transformation( xco_cp_xlsx_read_access=>value_transformation->string_value
      )->execute( ).
  ENDMETHOD.

  METHOD get_instance_features.
    READ ENTITIES OF zapp_i_table IN LOCAL MODE
         ENTITY app
         ALL FIELDS WITH
         CORRESPONDING #( keys )
         RESULT DATA(lt_data).
    result = VALUE #(
        FOR ls_data IN lt_data
        ( %tky                     = ls_data-%tky

          %action-LoadExcelContent = COND #( WHEN ls_data-ExcelAttachment IS NOT INITIAL
                                             THEN if_abap_behv=>fc-o-enabled
                                             ELSE if_abap_behv=>fc-o-disabled   ) ) ).
  ENDMETHOD.

ENDCLASS.

CLASS lsc_ZAPP_I_TABLE DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_ZAPP_I_TABLE IMPLEMENTATION.

  METHOD save_modified.
    LOOP AT update-app INTO DATA(ls_new_app).

*      INSERT zapp_table FROM @ls_new_app MAPPING FROM ENTITY.
*      IF sy-subrc <> 0.
      UPDATE zapp_table FROM @ls_new_app INDICATORS SET STRUCTURE %control MAPPING FROM ENTITY.
*      ENDIF.
    ENDLOOP.

    LOOP AT create-country INTO DATA(ls_create_country).
      INSERT zapp_curr_table FROM @ls_create_country MAPPING FROM ENTITY.
    ENDLOOP.

    LOOP AT update-country INTO DATA(ls_update_country).
      UPDATE zapp_curr_table FROM @ls_update_country INDICATORS SET STRUCTURE %control MAPPING FROM ENTITY.
    ENDLOOP.

    LOOP AT delete-country INTO DATA(ls_delete_country).
      DELETE zapp_curr_table FROM @( CORRESPONDING zapp_curr_table( ls_delete_country MAPPING FROM ENTITY ) ).
    ENDLOOP.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
