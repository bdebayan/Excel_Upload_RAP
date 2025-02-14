@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'App Overview'
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity zapp_c_table
  provider contract transactional_query
  as projection on zapp_i_table
{
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 1.0
      @Search.ranking: #HIGH
      @UI:{
      lineItem: [{ position: 10 }],
      selectionField: [{ position: 10 }],
      identification: [{ type: #FOR_ACTION, dataAction: 'LoadExcelContent', label: 'Load Excel' }]
      }
  key AppId,
      @Semantics.largeObject: {
          mimeType : 'ExcelMimetype',
          fileName : 'ExcelFilename',
          contentDispositionPreference: #INLINE
          }
      ExcelAttachment,
      @Semantics.mimeType: true
      ExcelMimetype,
      ExcelFilename,
      Locallastchanged,
      Lastchanged,
      /* Associations */
      _currency : redirected to composition child zapp_c_curr_table
}
