**Project Title:** Automatic KYC’d Gatekeeping Layer for Compliant DeFi on Polkadot

### **Overview:**

This project introduces a permissioned liquidity pool tailored for institutions and individuals seeking regulatory compliance within the DeFi ecosystem—specifically for smart contracts deployed on the Polkadot network. It leverages automatic verification of accounts' KYC status through the "well known" designation on the People system parachain, ensuring that only authenticated and trusted participants can interact with designated contracts and effectively transact with each other. This gatekeeping mechanism operates seamlessly as an access control layer, filtering interactions to verified accounts only.

### Roadmap:

- **v1**: In our MVP, user whitelisting for interacting with the smart contracts and accessing the compliant DeFi infrastructure is managed via an on-chain mapping within the contracts. The dApp verifies the status of prospective accounts on the People chain off-chain, and, if eligible, calls the contract to add them to the authorized mapping
- **v2**: In the next few months, with the release of [PR #**7896**](https://github.com/paritytech/polkadot-sdk/pull/7896), smart contracts should gain the ability to verify user statuses on the People chain directly on-chain via XCM. This will enable native whitelisting, eliminate reliance on off-chain verification, and reduce the risk of contract exploits by seamlessly checking for an account’s “well-known” status.
- **v3**: Introduce privacy features by integrating zero-knowledge proofs (ZKPs) to mask transaction activity. This allows accounts to interact with smart contracts in a compliant manner — using their publicly known identity — while keeping transaction details (e.g., amounts, destinations, or function parameters) confidential. The goal is to ensure regulatory alignment without exposing full transaction history or patterns on-chain. (https://github.com/advaita-saha/zk-Voting)

### **Key Features:**

- **KYC Verification via People Chain Registrars:**
    
    The system automatically verifies whether a user has completed a KYC process through the authorized registrars on the People system parachain. These registrars act as gatekeepers, assigning a "well known" status to verified accounts.
    
- **Decentralized Integration on Polkadot:**
    
    Built within the Polkadot ecosystem, the solution takes full advantage of its interoperability and shared security model. It integrates with the People chain for decentralized identity verification, ensuring transparency, resilience, and alignment with Polkadot-native infrastructure.
    
- **Seamless Smart Contract Interaction:**
    
    Acting as a middleware layer, the tool intercepts interactions with the contract. It pre-validates each request against the KYC status, ensuring that only compliant users can trigger contract functions. This allows for secure execution without exposing sensitive personal data.
    
- **Enhanced Security & Compliance:**
    
    By enforcing KYC requirements validated by trusted registrars, the solution significantly reduces risks associated with fraud, money laundering, and unauthorized access. It offers a strong compliance layer, fostering trust among institutional participants, individuals, and regulators.
    

### **Architecture Overview:**

1. **User KYC & Verification:**
    
    Users undergo KYC through approved registrars on the People Chain. Upon successful verification, they are assigned a “well known” status.
    
2. **Identity Availability:**
    
    This status is made available on-chain on the People chain and can be queried to assess the identity status of an account.
    
3. **Smart Contract Interaction:**
    
    Before any interaction with the smart contracts, the system (either off chain or on-chain, when available) checks the account’s identity status. If the account holds a valid "well known" status, the contract function proceeds; otherwise, access is denied.
    
4. **Compliance & Security:**
    
    This ensures DeFi participation is limited to verified users, satisfying institutional compliance requirements and improving protection against illicit activity.
    

### **Revenue Model:**

While the infrastructure enforces compliance and access control, the underlying mechanics follow a standard decentralized exchange (DEX) model. The protocol generates revenue through:

- **Transaction Fees:**
    
    Every swap or liquidity operation executed through the permissioned DEX incurs a transaction fee, similar to traditional AMMs.
    
- **Liquidity Provider Incentives:**
    
    Liquidity providers earn a share of these transaction fees proportional to their pool contribution, encouraging participation from compliant actors.
    

By combining a familiar DeFi fee model with a robust compliance layer, the project offers a sustainable revenue stream while ensuring only verified participants contribute to and benefit from the solution.
