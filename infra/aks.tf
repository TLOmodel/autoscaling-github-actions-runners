# See https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster
resource "azurerm_kubernetes_cluster" "sample" {
  name                = "cluster-${var.azure_suffix}" # name of cluster
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_prefix          = "dns-${var.azure_suffix}"
  # For long-term deployments, this ensure we're always running a supported version of
  # Kubernentes.
  automatic_channel_upgrade = "stable"

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name                = "agentpool"
    vm_size             = "Standard_E2a_v4"
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 8
    # With Kubernetes 1.29+, the maximum number of pods affects the maximum amount of memory
    # actually allocatable on a node:
    # <https://learn.microsoft.com/en-us/azure/aks/concepts-clusters-workloads#memory>.
    # Since we don't need a large number of pods (default is 110), we can limit them in
    # exchange of more memory.
    max_pods                    = 50
    temporary_name_for_rotation = "temppoolname"
  }

  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
  }

  api_server_access_profile {
    authorized_ip_ranges = ["${data.http.deployer_ip.response_body}/32"]
  }

  auto_scaler_profile {
    max_unready_nodes          = 1
    scale_down_delay_after_add = "1m"
  }
}

resource "local_sensitive_file" "kubeconfig" {
  filename = "${path.module}/../kubeconfig.yaml"
  content  = azurerm_kubernetes_cluster.sample.kube_config_raw
}
