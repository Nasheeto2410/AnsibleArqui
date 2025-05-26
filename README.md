# 🤖 Ansible Automation – LAB-IT-UAI

This directory serves as the foundation for managing and deploying the entire infrastructure of **IT-LAB-UAI** using Ansible. The goal is to ensure that every component in the lab — from workstations to network configurations — can be consistently provisioned, maintained, and reset using automated playbooks.

By leveraging **Ansible**, we ensure:

- **Consistency** across machines and environments.
- **Repeatability** of installations and setups.
- **Idempotency**, meaning playbooks can be run multiple times without causing unintended side effects.
- **Simplicity**, with readable YAML-based playbooks and no need for agents on target machines.

The idea behind this structure is that **everything in the infrastructure should be buildable and recoverable through code**, offering full control and auditability of every stateful change in the LAB.

## 🧩 Context and Integration

The playbooks in this repository are intended to be used **after the machines have been booted and initialized**, such as through the PXE boot process previously documented.

> 📦 Reference: [PXE Boot Project Documentation](https://github.com/IT-LAB-UAI/Documentation/blob/main/PXE/README.md)

These playbooks assume that:
- Machines already have a network connection
- An SSH-accessible user (e.g., `lab`) exists, as defined in the PXE setup

Ansible is used at this stage to **apply consistent configurations across all machines**, ensuring that key system states — such as installed packages, user setups, or network settings — are aligned throughout the LAB environment.

This approach allows for changes to be **propagated horizontally**, reducing manual work and maintaining a reproducible, version-controlled infrastructure.

## 🔐 Security Considerations

These playbooks are designed to install an **SSH public key** on each target machine to enable passwordless Ansible access in future runs.

Because of this, it is strongly recommended that you deploy these playbooks **from a dedicated control machine inside the LAB** (e.g., the main server), and not from a personal laptop or temporary workstation. Otherwise:

- Your SSH key will be injected into **every machine** listed in the inventory
- All target machines will add your personal machine to their `known_hosts` list

Centralizing Ansible execution ensures tighter control over who has remote access and keeps the automation footprint consistent across the LAB.



## 🧭 Overview of Directories
