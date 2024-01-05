output "resource_id" {
    value = jsondecode(azurerm_resource_group_template_deployment.github_network_settings.output_content).gitHubId.value
}
