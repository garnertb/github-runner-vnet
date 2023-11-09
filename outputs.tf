output "nsg_id" {
  value = azurerm_network_security_group.actions_NSG.id
}

output "network_provider" {
  value =data.azurerm_resources.github_network_provider.resources[0].tags.GitHubId
}
