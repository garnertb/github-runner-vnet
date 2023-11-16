output "networkSettings_id" {
  value = jsondecode(data.local_file.ns.content).GitHubId
}
