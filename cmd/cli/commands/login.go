package commands

import (
	"os"

	"github.com/ethereum/go-ethereum/crypto"
	"github.com/sonm-io/core/accounts"
	"github.com/sonm-io/core/util"
	"github.com/spf13/cobra"
)

var loginCmd = &cobra.Command{
	Use:   "login [addr]",
	Short: "Open or generate Etherum keys",
	Run: func(cmd *cobra.Command, args []string) {
		ks, err := initKeystore()
		if err != nil {
			showError(cmd, "Cannot init keystore", err)
			os.Exit(1)
		}

		if len(args) > 0 { // have a key
			if len(ks.List()) == 0 {
				showError(cmd, "Cannot switch default address: keystore is empty", nil)
				os.Exit(1)
			}

			// check if valid
			addr, err := util.HexToAddress(args[0])
			if err != nil {
				showError(cmd, err.Error(), nil)
				os.Exit(1)
			}

			if err := ks.SetDefault(addr); err != nil {
				cmd.Printf("Given address is not present into keystore.\r\nAvailable addresses:\r\n")
				for _, addr := range ks.List() {
					cmd.Println(addr.Address.Hex())
				}
				return
			}

			// ask for password for default key
			pass, err := accounts.NewInteractivePassPhraser().GetPassPhrase()
			if err != nil {
				showError(cmd, "Cannot read pass phrase", err)
				os.Exit(1)
			}

			// try to decrypt default key with given pass
			if _, err := ks.GetKeyWithPass(addr, pass); err != nil {
				showError(cmd, "Cannot decrypt default key with given pass", err)
				os.Exit(1)
			}

			cfg.Eth.Passphrase = pass
			cfg.Save()

			cmd.Printf("Set \"%s\" as default keystore address\r\n", addr.Hex())
		} else { // no keys
			ls := ks.List()
			if len(ls) == 0 {
				// generate new key
				cmd.Println("Keystore is empty, generating new key...")
				// ask for password for default key
				pass, err := accounts.NewInteractivePassPhraser().GetPassPhrase()
				newKey, err := ks.GenerateWithPassword(pass)
				if err != nil {
					showError(cmd, "Cannot generate new key", err)
					os.Exit(1)
				}
				cmd.Printf("Generated key %s set as default\r\n", crypto.PubkeyToAddress(newKey.PublicKey).Hex())
				cfg.Eth.Passphrase = pass
				cfg.Save()
				return
			}

			defaultAddr, err := ks.GetDefaultAddress()
			if err != nil {
				cmd.Printf("No default address for account, select one from list and use `sonmcli login [addr]`\r\n")
			} else {
				cmd.Printf("Default key: %s\r\n", defaultAddr.Hex())
			}

			cmd.Println("Keystore contains following keys:")
			for _, acc := range ls {
				cmd.Printf("  %s\r\n", acc.Address.Hex())
			}
		}
	},
}
