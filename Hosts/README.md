# 🕵️ Host Scan Playbook – Ansible

This Ansible playbook is designed to perform a **network scan on a specified subnet**, identifying reachable hosts and automatically generating an Ansible-compatible inventory file based on the discovered IPs.

If you’re setting up a complete lab deployment, **this is the first playbook you should run**, as it prepares the dynamic inventory required for future provisioning steps.

## ⚠️ Legal & Ethical Notice

This playbook uses [`nmap`](https://nmap.org/) to scan IPs within a given subnet. While `nmap` is a powerful and widely used tool, **network scanning may be considered intrusive or illegal if run in unauthorized environments.**

Please ensure that:

-   You **own** or have **administrative rights** on the network you’re scanning.
-   You understand any **local legal restrictions**, such as those outlined by law.
-   You **do not use this playbook** on public or unapproved networks.

## 🧾 Chilean Legal Context – Cybersecurity Law

In Chile, network and cybersecurity practices are governed by the **Cybersecurity Framework Law (Ley N° 21.663)**, which came into effect on **January 1, 2025**. This law defines strict regulations for the protection of critical information systems and places legal obligations on both public and private entities that manage essential services.

Running automated tools like `nmap` to scan networks without explicit authorization could be interpreted as a legal violation — particularly in sensitive environments or on networks you do not own.

If you are operating within Chile, it is your responsibility to:

-   Ensure you are **authorized** to perform scans on the target network.
-   Avoid using this playbook on **public**, **external**, or **third-party** networks without consent.
-   Understand the scope and limitations of your administrative access.

📄 You can read the full [legal text](https://www.bcn.cl/leychile/navegar?i=1202434) on the official Chilean **Library of Congress** website

## 🧠 What This Playbook Does

The playbook performs the following:

1. Scans a user-defined subnet using `nmap`.
2. Extracts active IP addresses that respond to ping or TCP connection checks.
3. Groups the discovered hosts into a dynamic inventory under a group name like `[lab_hosts]`.
4. Saves the inventory to a file (e.g., `hosts.ini`) for later use in other Ansible playbooks.

## 📂 Project Structure

```bash
../Ansible
├── LICENSE
├── Outputs
│   ├── ...
│   └── Hosts_Scan_Output
│       └── active_hosts.ini       # This file will be generated
├── README.md
└── Setups
    ├── ...
    ├── Hosts_Scan_Setup
    │   ├── hosts_scan.yml         # Playbook for this project
    │   ├── README.md
    │   └── secrets_hosts_scan.yml # Secrets for this project
    └── ...
```

## 🔐 secrets_hosts_scan.yml

This playbook uses a **vault-encrypted variable file** named `secrets_hosts_scan.yml` to store sensitive credentials and scanning parameters.

### 📦 Creating and Encrypting the Vault File

To create the secrets file and encrypt it with Ansible Vault:

```bash
ansible-vault create secrets_hosts_scan.yml
```

Or, if you're editing an existing unencrypted file:

```bash
ansible-vault encrypt secrets_hosts_scan.yml
```

You’ll be prompted to enter a password that will be required every time the file is used or edited. To run the playbook with the vault, include the `--ask-vault-pass` flag:

```bash
ansible-playbook hosts_scan.yml --ask-vault-pass
```

---

### 🔧 Variables Defined

```yaml
inventory_group_name: "Scanned_Hosts" # Group name for the generated inventory
ansible_become_user: root # Privilege escalation user
ansible_become_pass: RootPass # Privilege escalation password (vault-encrypted)
subnet: "192.168.3.0/24" # Subnet to scan for live hosts
ip_upper_limit: 50 # Limit host scan to low-numbered IPs
```

---

### 📌 Why Use `ip_upper_limit`?

In our lab’s network (`192.168.3.0/24`), we’ve divided IP usage into two zones:

-   **IPs 1–50**: assigned dynamically via **DHCP** to new or temporary devices
-   **IPs 51–254**: reserved for **statically assigned IPs** to pre-configured machines

By setting `ip_upper_limit` (e.g., `50`), we ensure that the playbook only includes newly added machines — avoiding interference with already configured systems. This helps us maintain a clean and predictable inventory for provisioning.

## ▶️ Running the Playbook

Once `secrets_hosts_scan.yml` is properly configured and encrypted (recommended for safe storage of credentials and network settings), you can run the playbook directly.

> For more information about vault usage, refer to the official [Ansible Vault documentation](https://docs.ansible.com/ansible/latest/user_guide/vault.html).

### 📥 Playbook Command

```bash
ansible-playbook hosts_scan.yml --ask-vault-pass
```

This will:

-   Prompt you for the vault password
-   Load the encrypted `secrets_hosts_scan.yml` variables
-   Run the host discovery and generate the dynamic inventory

## 🧠 Playbook Breakdown

This playbook is designed to detect active IPs on a given subnet and output an Ansible inventory file for dynamic use.

---

### 🎯 Playbook Metadata

```yaml
- name: Discover active IPs on a network using nmap
  hosts: localhost
  gather_facts: no
  become: true

  vars_files:
      - scan_settings.yml
```

🔹 **What it does:**

-   Runs **locally** (not on remote hosts).
-   Skips fact gathering to speed things up.
-   Uses **`become: true`** to ensure `nmap` can run with proper privileges.
-   Loads external variables from `scan_settings.yml` (e.g., subnet, IP range limits, group name).

---

### 🧰 Ensure nmap is installed

```yaml
- name: Ensure nmap is installed
  ansible.builtin.package:
      name: nmap
      state: present
```

🔹 **Explanation:**  
Checks that `nmap` is available. Installs it if missing. This is essential for scanning the network.

---

### 🌐 Run nmap ping scan

```yaml
- name: Run nmap ping scan on the subnet
  ansible.builtin.command: "nmap -sn --host-timeout 10s {{ subnet }}"
  register: nmap_output
```

🔹 **Explanation:**  
Executes a **ping scan** (`-sn`) on the target subnet. The `--host-timeout` limits how long to wait for each host. The output is saved to `nmap_output`.

---

### 🔎 Extract IPs from output

```yaml
- name: Extract all IPs from nmap output
  set_fact:
      raw_active_ips: "{{ nmap_output.stdout | regex_findall('\\d+\\.\\d+\\.\\d+\\.\\d+') | unique }}"
```

🔹 **Explanation:**  
Uses a regex to extract all IP addresses from the scan output and stores them in `raw_active_ips`. Filters out duplicates with `unique`.

---

### 🖥️ Get the IP address(es) of the current machine

```yaml
- name: Get the IP address(es) of the current machine
  ansible.builtin.command: "hostname -I"
  register: local_ips_raw
```

🔹 **Explanation:**  
Fetches the IP addresses assigned to the local machine using `hostname -I`. This is needed so we can **exclude** the control node from the scanned inventory.

---

### 🧼 Parse local IPs into a list

```yaml
- name: Parse local IPs into a list
  set_fact:
      local_ips: "{{ local_ips_raw.stdout.split() }}"
```

🔹 **Explanation:**  
Converts the string of space-separated IPs into a proper list (`local_ips`) so we can work with it using Ansible filters.

---

### 🚫 Filter out local IPs from discovered ones

```yaml
- name: Filter out local IPs from discovered ones
  set_fact:
      active_ips: "{{ raw_active_ips | difference(local_ips) }}"
```

🔹 **Explanation:**  
Removes the local machine's IPs from the list of scanned IPs — ensuring we don’t accidentally include the control node in the output inventory.

---

### 🎯 Filter IPs with last octet < ip_upper_limit

```yaml
- name: Filter IPs with last octet < ip_upper_limit
  set_fact:
      filtered_ips: []
```

🔹 **Explanation:**  
Initializes an empty list to hold only the IPs that meet our defined upper limit filter. This prepares the variable for the upcoming loop.

```yaml
- name: Add allowed IPs to filtered list
  set_fact:
      filtered_ips: "{{ filtered_ips + [item] }}"
  loop: "{{ active_ips }}"
  when: "(item.split('.')[-1] | int) < ip_upper_limit"
```

🔹 **Explanation:**  
Loops through the active IPs and adds only those with a **last octet lower than `ip_upper_limit`** (e.g., < 50). This avoids including statically assigned IPs.

```yaml
- name: Set active_ips to filtered list
  set_fact:
      active_ips: "{{ filtered_ips }}"
```

🔹 **Explanation:**  
Overrides the `active_ips` variable with the filtered list. This makes sure the rest of the playbook uses the cleaned list of IPs.

---

### 🧾 Show final filtered IPs

```yaml
- name: Show final filtered IPs
  debug:
      msg: "Final IPs for inventory: {{ active_ips }}"
```

🔹 **Explanation:**  
Prints the list of filtered IPs to the terminal. This gives immediate visibility into what hosts will be added to the inventory file.

---

### 🗂️ Create a file with active IPs

```yaml
- name: Create a file with active IPs
  ansible.builtin.copy:
      dest: ../../Output/Hosts_Scan_Output/active_hosts.txt
      content: |
          [{{ inventory_group_name }}]
          {% for ip in active_ips %}
          {{ ip }}
          {% endfor %}
  delegate_to: localhost
```

🔹 **Explanation:**  
Generates an **Ansible-compatible inventory file** with the list of active hosts grouped under the specified name (from `inventory_group_name`).

-   The file is saved in: `../../Output/Hosts_Scan_Output/active_hosts.ini`
-   The format matches what Ansible expects, e.g.:

```ini
[Scanned_Hosts]
192.168.3.2
192.168.3.3
```

Using `delegate_to: localhost` ensures this file is created on the control machine, not a remote host.

---

✅ With that, the playbook completes its task: scanning, filtering, and generating a clean dynamic inventory ready for use in other Ansible deployments.
