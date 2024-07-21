########################
# Create SQL warehouse
########################

resource "databricks_sql_endpoint" "this" {
  name             = "dw-2x-small"
  cluster_size     = "2X-Small"
  auto_stop_mins   = 30
  warehouse_type   = "PRO"
  max_num_clusters = 1

  depends_on = [azurerm_databricks_workspace.this]
}

#############################
# Creat external connection
#############################

resource "databricks_connection" "redshift" {
  name            = "redshift_sandbox"
  connection_type = "REDSHIFT"
  comment         = "This is a connection to a Redshift sandbox"
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

#########################################
# Creat catalog for external connection
#########################################

resource "databricks_catalog" "redshift_sandbox" {
  name            = "redshift_sandbox"
  connection_name = databricks_connection.redshift.name
  comment         = "This catalog contains external data from Redshift"

  options = {
    "database" = "sandbox"
  }

  properties = {
    purpose = "testing"
  }
}
