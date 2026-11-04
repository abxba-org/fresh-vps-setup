Fill this up


{
# Add cloudflare gpg key
sudo mkdir -p --mode=0755 /usr/share/keyrings
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null

# Add this repo to your apt repositories
echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' | sudo tee /etc/apt/sources.list.d/cloudflared.list

# install cloudflared
sudo apt-get update && sudo apt-get install cloudflared


# Before modifying tunnels or scripts, first run:
sudo cloudflared service uninstall

2. Install as service goto Cloudflare tunnels to setup the tunnel 

sudo cloudflared service install eyJhIjoi********************9In0=


Also publish the route to connect with the tunnel with Cloudflare Applications

}
