output "resource_id" {
    value = data.azurerm_resources.github_network_settings.resources[0].tags.GitHubId
}
