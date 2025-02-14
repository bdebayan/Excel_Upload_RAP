@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Currency Table'
@Metadata.allowExtensions: true
define view entity zapp_c_curr_table as projection on zapp_i_curr_table
{
    key AppId,
    @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CountryVH', element: 'Country' } }]
    key Country,
    Ranking,
    Text,
    /* Associations */
    _app : redirected to parent zapp_c_table
}
