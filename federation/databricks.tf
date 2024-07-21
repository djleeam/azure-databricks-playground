resource "databricks_sql_endpoint" "this" {
  name             = "dw-2x-small"
  cluster_size     = "2X-Small"
  auto_stop_mins   = 30
  warehouse_type   = "PRO"
  max_num_clusters = 1

  depends_on = [azurerm_databricks_workspace.this]
}

resource "databricks_connection" "redshift" {
  name            = "redshift_sandbox"
  connection_type = "REDSHIFT"
  comment         = "this is a connection to a Redshift sandbox"
  options = {
    host     = var.redshift_host
    port     = "5439"
    user     = "testuser"
    password = var.redshift_password
  }
  properties = {
    purpose = "testing"
  }

  depends_on = [azurerm_databricks_workspace.this]
}
