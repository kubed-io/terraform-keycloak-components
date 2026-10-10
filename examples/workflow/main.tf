terraform {
  required_providers {
    keycloak = {
      source  = "keycloak/keycloak"
      version = "5.9.0"
    }
  }
}

provider "keycloak" {
  # client_id = "admin-cli"
  # url       = "https://auth.example.com"
  # username  = "admin"
  # password  = var.admin_password
}

# Invite every person an admin creates: Keycloak emails them a link to set a password.
module "invite_new_people" {
  source = "../../modules/workflow"

  realm = "example"
  name  = "invite-new-people"
  on    = "user-created"
  steps = [{ uses = "invite-user" }]
}

# Nudge people who stop logging in, then disable them. Each login restarts the countdown.
module "track_inactive_users" {
  source = "../../modules/workflow"

  realm       = "example"
  name        = "track-inactive-users"
  on          = "user-authenticated"
  conditions  = "not is-member-of(/admins)"
  concurrency = "restart-in-progress"
  steps = [
    {
      uses   = "notify-user"
      after  = "180d"
      config = { message = "It has been a while since your last login." }
    },
    { uses = "disable-user", after = "7d" },
  ]
}

output "workflows" {
  value = {
    invite_new_people    = module.invite_new_people
    track_inactive_users = module.track_inactive_users
  }
}
