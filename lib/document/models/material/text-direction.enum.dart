// This model exists only to help us isolate the DocumentController completely from material.
// By not having any material reference it means we don't need dart:ui,
// which means we can run the document controller in a dart backend.
// Thus it enables us to process delta docs on server side.
// Without this model we would be forced to split the search features
// from DocumentController in a dedicated SearchController.
enum TextDirectionE {
  rtl,
  ltr,
}
