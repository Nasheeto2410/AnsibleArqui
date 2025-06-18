# 🌐 Ansible – Network Setup

This setup contains the Ansible playbooks used to **assign static IPs** and **standardized hostnames** to all lab machines in the IT-LAB-UAI environment.

After machines are provisioned via PXE and **secured through the [Computer Setup Project](https://github.com/IT-LAB-UAI/Documentation/blob/main/Ansible/Setups/Computers_Setups/README.md)**, their network identity should be formalized.  
This project allows you to consistently name and configure each host with a **predictable static IP and hostname**, helping ensure that infrastructure automation can rely on a stable network configuration.

## 🧩 Purpose & Scope

The main objectives of this setup are:

-   🗺️ **Map** current lab machines based on their dynamic PXE-assigned IPs and hostnames
-   🧾 **Generate structured data** for renaming hosts and assigning static IPs
-   🖥️ **Update** each host’s hostname and apply static IP configuration using NetworkManager
-   🔁 Ensure the machines reboot to apply all changes cleanly

This project is composed of two playbooks:

1. `generate_network_map.yml` – collects information about current machines and creates a YAML+INI file for assigning new hostnames and IPs.
2. `update_network_host.yml` – applies the new network configuration to each host using `nmcli`.

> 📌 This setup is designed to run **after** PXE installation and **after [admin account creation is complete](https://github.com/IT-LAB-UAI/Documentation/blob/main/Ansible/Setups/Computers_Setups/README.md)**, and **before** any additional machine grouping or role-specific automation is applied.

## ⚙️ Prerequisites

Before using this network setup, ensure the following conditions are met:

-   ✅ All lab machines are already installed with the base OS (e.g., via PXE).
-   ✅ SSH access is available using a common admin user (e.g., `labadmin`).
-   ✅ The control node (your Ansible machine) has access to the same subnet.
-   ✅ An up-to-date Ansible inventory (`hosts.ini`) exists pointing to all machines to be reconfigured.
-   ✅ You have run the [Computer Setup Playbooks](https://github.com/IT-LAB-UAI/Documentation/blob/main/Ansible/Setups/Computers_Setups/README.md) to:
    -   Set up passwordless SSH
    -   Create the `labadmin` user
-   ✅ Your system uses **NetworkManager** as the network backend (`nmcli` must work).

> 📝 If you haven't generated your inventory yet, use the [Host Scan Project](https://github.com/IT-LAB-UAI/Documentation/blob/main/Ansible/Setups/Hosts_Scan_Setup/README.md) to discover machines automatically.

## 📁 Project Structure

This network setup is organized to separate logic (playbooks) from generated outputs, keeping things clean and traceable.

```
Ansible
├── Outputs
│   └── Network_Setup_Output
│       ├── new_hosts.ini           # Generated inventory with updated IPs
│       └── network_plan.yml        # YAML map of current and new hostnames/IPs
└── Setups
    └── Network_Setup
        ├── ansible.cfg             # Configuration file pointing to hosts.ini
        ├── generate_network_plan.yml  # Scans network and creates the plan
        ├── update_hosts_network.yml  # Applies the changes (hostname + IP)
        └── network_setup_secrets.yml # Vault file with SSH credentials
```

---

### 🧾 File Descriptions

-   **`ansible.cfg`** – Points to your current working inventory (`hosts.ini`) so Ansible can connect to the machines to be configured.

-   **`generate_network_map.yml`** – Scans the lab machines to collect current hostnames and IPs, then generates two output files:

    -   `network_plan.yml`: Maps each machine’s current IP and hostname to its future configuration.
    -   `new_hosts.ini`: A refreshed Ansible inventory with updated IPs and a shared `ansible_user`.

-   **`update_hosts_network.yml`** – Reads the `network_plan.yml` file and applies the changes using `nmcli`:

    -   Changes hostname
    -   Configures a static IP address
    -   Updates `/etc/hosts`
    -   Restarts the network and reboots the machine to finalize changes

-   **`network_setup_secrets.yml`** – A vault-encrypted file containing SSH credentials used to access the machines and apply changes.

-   **`network_plan.yml`** – A structured YAML file (auto-generated) that outlines the **migration plan** from current to new hostnames and IPs.

-   **`new_hosts.ini`** – The output inventory that reflects all machines **after** they’ve been renamed and readdressed. This can be used in future Ansible playbooks.
