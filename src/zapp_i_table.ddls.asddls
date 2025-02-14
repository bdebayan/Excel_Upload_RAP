@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'App Overview'
@Metadata.ignorePropagatedAnnotations: true
define root view entity zapp_i_table
  as select from zapp_table 
  composition of many zapp_i_curr_table as _currency
{
  key app_id           as AppId,
      excel_attachment as ExcelAttachment,
      excel_mimetype   as ExcelMimetype,
      excel_filename   as ExcelFilename,
      locallastchanged as Locallastchanged,
      lastchanged      as Lastchanged,
      _currency // Make association public
}
