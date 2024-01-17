output "network_settings_id" {
    description = "ID of the GitHub.Network/networkSettings resource"
    value = jsondecode(azurerm_resource_group_template_deployment.github_network_settings.output_content).gitHubId.value
}
