terraform {
  backend "gcs" {
    bucket = "state-storage02"
  }
}
