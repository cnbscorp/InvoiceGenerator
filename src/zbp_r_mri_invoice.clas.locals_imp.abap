CLASS lhc_zr_mri_invoice DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    CLASS-DATA: mt_data TYPE zmri_invoice.

    DATA: lv_length    TYPE i,
          lt_data_tab  TYPE STANDARD TABLE OF xstring,
          lv_content   TYPE xstring,
          lv_xml       TYPE xstring,
          lv_docx      TYPE xstring,
          lv_xstring   TYPE xstring,
          lv_base64dec TYPE string,
          lv_raw       TYPE string,
          lt_entries   TYPE cl_abap_zip=>t_splice_entries,
          lo_zip       TYPE REF TO cl_abap_zip.

    METHODS:
      get_global_authorizations FOR GLOBAL AUTHORIZATION
        IMPORTING
        REQUEST requested_authorizations FOR ZrMriInvoice
        RESULT result,

      get_global_features FOR GLOBAL FEATURES
        IMPORTING
        REQUEST requested_features FOR ZrMriInvoice
        RESULT result,

      createMSWordInvoice FOR MODIFY
        IMPORTING keys FOR ACTION ZrMriInvoice~createMSWordInvoice.

ENDCLASS.

CLASS lhc_zr_mri_invoice IMPLEMENTATION.

  METHOD get_global_authorizations.
*  This method does not need an implementation
  ENDMETHOD.

  METHOD createMSWordInvoice.

*     Select document to be filled
    SELECT * FROM zc_mri_invoice
     FOR ALL ENTRIES IN @keys
     WHERE invoice      = @keys-invoice
     INTO CORRESPONDING FIELDS OF @mt_data.
    ENDSELECT.

*     Create zip class instance
    lo_zip = NEW cl_abap_zip( ).

*     Search for main document part
    DATA lv_index TYPE string VALUE 'word/document.xml'.

*     Load attachment into zip class object
    lo_zip->load( zip = mt_data-attachment check_header = abap_false ).

*     Fetch the binaries of the XML part in the attachment
    lo_zip->get(
    EXPORTING
      name   = lv_index
    IMPORTING
      content = lv_content
    ).


* Convert the binaries of the xml into a string
    DATA(lv_string) = xco_cp=>xstring( lv_content
      )->as_string( xco_cp_character=>code_page->utf_8
      )->value.

* Search for the text to be replaced and fill with the information in your data set
    REPLACE FIRST OCCURRENCE OF '&lt;InvoiceNumber&gt;' IN lv_string
    WITH mt_data-Invoice.

    REPLACE FIRST OCCURRENCE OF '&lt;Purchase Order&gt;' IN lv_string
WITH mt_data-PurchaseOrder.

    REPLACE FIRST OCCURRENCE OF '&lt;Comments&gt;' IN lv_string
WITH mt_data-Comments.

    DATA lv_price TYPE string.
    lv_price = mt_data-Price.

    REPLACE FIRST OCCURRENCE OF '&lt;Price&gt;' IN lv_string
WITH lv_price.


    APPEND VALUE #( %msg = new_message_with_text( severity = if_abap_behv_message=>severity-success text = 'Template successfully filled...' ) ) TO reported-ZrMriInvoice.

* Convert the changed XML string into binaries
    DATA(lv_new_content) = xco_cp=>string( lv_string )->as_xstring( xco_cp_character=>code_page->utf_8
    )->value.

* Delete "old" main document part from the zip file
    lo_zip->delete(
  EXPORTING
    name   = lv_index
  ).

* ADd "new" main document part to the zip file
    lo_zip->add(

    EXPORTING
      name   = lv_index
      content = lv_new_content

    ).

* Save the new zip file
    DATA(lv_new_file) = lo_zip->save( ).

* Upload changed docx file
    MODIFY ENTITIES OF zr_mri_invoice IN LOCAL MODE ENTITY ZrMriInvoice
      UPDATE SET FIELDS WITH
      VALUE #( (
          Invoice = mt_data-Invoice
          Attachment = lv_new_file
      )  )
    FAILED failed.


  ENDMETHOD.

  METHOD get_global_features.
* This method does not need to be implemented
  ENDMETHOD.


ENDCLASS.
