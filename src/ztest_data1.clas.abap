CLASS ztest_data1 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ztest_data1 IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
    DATA: lt_tab TYPE STANDARD TABLE OF zapp_table.
    DATA: lt_tab_curr TYPE STANDARD TABLE OF zapp_curr_table.
    DATA: ls_tab TYPE zapp_table.
    DELETE FROM zapp_table.
    lt_tab = VALUE #( ( app_id = 'Maintain Country Table' ) ).
    MODIFY zapp_table FROM TABLE @lt_tab.

    lt_tab_curr = VALUE #( ( app_id = 'Maintain Country Table'
                             country = 'DE'
                             ranking = 1
                             text = 'Country1' )
                            ( app_id = 'Maintain Country Table'
                             country = 'IN'
                             ranking = 2
                             text = 'Country2' )
                             ).

    MODIFY zapp_curr_table FROM TABLE @lt_tab_curr.
    COMMIT WORK.
  ENDMETHOD.
ENDCLASS.
