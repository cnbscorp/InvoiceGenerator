@Metadata.allowExtensions: true
@EndUserText.label: '###GENERATED Core Data Service Entity'
@AccessControl.authorizationCheck: #CHECK
define root view entity ZC_MRI_INVOICE
  provider contract transactional_query
  as projection on ZR_MRI_INVOICE
{
  key Invoice,
  Comments,
  Attachment,
  MimeType,
  Filename,
  PurchaseOrder,
  Price,
  LocalCreatedBy,
  LocalCreatedAt,
  LocalLastChangedBy,
  LocalLastChangedAt,
  LastChangedAt
  
}
