@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Currency Table'
@Metadata.ignorePropagatedAnnotations: true
define view entity zapp_i_curr_table
  as select from zapp_curr_table
  association to parent zapp_i_table as _app on $projection.AppId = _app.AppId
{
  key app_id  as AppId,
  key country as Country,
      ranking as Ranking,
      text    as Text,
      _app // Make association public
}
