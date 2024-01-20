# ssh ca setup, to allow for me to swap between blue/green ssh host ca's
#
# This also lets me generate ssh host keys I can then more easily use in
# secrets/secrets.nix for age secret usage as well as to provide to any of my
# nix built systems directly so that I eliminate all TOFU ssh key nonsense.
#
# I can also then have nix setup/use both the blue/green ca authorities for
# validation so that I can swap between ca authorities if needed.
#
# Plan is to probably rotate host ca's yearly with a 2 year stippled interval.
#
# TODO: User ssh key setup as well once this is all kosher.

# Note this is all RFC compliant internal home network dns no .lan or whatever
# rubbish that is wrong.
TLD:=.home.arpa

# TODO: later for now one ca for simplicity
#HOSTCA:=green-host-ca blue-host-ca
HOSTCA:=green
HOSTDIR:=hosts
HOSTNAMES:=foo bar
# The hostkey types we generate, need to validate if I truly need all of them
# for compatibility with say old openssh or whatever macos uses.
HOSTNAME_KEYTYPES:=ed25519 ecdsa dsa rsa
_HOSTNAME_KEYPATHS:=$(foreach keytyp,$(HOSTNAME_KEYTYPES),/ssh_host_$(keytyp)_key)
HOSTNAME_DIRS:=$(foreach hostpath,$(addprefix $(HOSTDIR)/$(HOSTCA)/, $(HOSTNAMES)),$(hostpath)$(TLD))
HOSTNAME_PRIV_KEYS:=$(addsuffix '', $(addsuffix "/ssh_host_", $(HOSTNAME_DIRS)) $(HOSTNAME_KEYTYPES))
HOSTNAME_PUB_KEYS:=$(addsuffix ".pub", $(HOSTNAME_PRIV_KEYS))

# append lhs to rhs e.g. lhs is prefixes to append to suffixes
#
# aka lhs = dira/ dirb/ rhs = a b c d = dira/a dira/b dira/c dira/d dirb/a dirb/b dirb/c dirb/d
define appendlists
	$(foreach prefix,$(1),$(foreach item,$(2),$(prefix)$(item)))
endef

ALL_HOST_PRIV_KEYS := $(call appendlists,$(HOSTNAME_DIRS),$(_HOSTNAME_KEYPATHS))
ALL_HOST_PUB_KEYS := $(addsuffix .pub,$(ALL_HOST_PRIV_KEYS))

CADIR=ca
$(CADIR):
	install -dm700 $@

CAS=$(addprefix "$(CADIR)/",$(HOSTCA))

all: $(CAS) $(ALL_HOST_PUB_KEYS)

$(CAS): $(CADIR)
	ssh-keygen -t ed25519 -C $@ -f $@
	chmod 600 $@.pub

$(HOSTNAME_DIRS):
	install -dm755 $@

$(ALL_HOST_PRIV_KEYS): $(HOSTNAME_DIRS) $(CAS)
	$(eval typ := $(shell echo $@ | sed -e 's/_key//g' -e 's/.*ssh_host_//g'))
	ssh-keygen -q -N "$@" -t $(typ) -f $@

# TODO: this might be better done with the same .c->.o approach where .pub -> non .pub gets generated
$(ALL_HOST_PUB_KEYS): $(ALL_HOST_PRIV_KEYS)
	$(eval typ := $(shell echo $@ | sed -e 's/_key//g' -e 's/.*ssh_host.*.pub//g'))
	$(eval hostname := $(shell echo $@ | sed -e 's/\/ssh_host.*.pub//g' -e 's/.*\///g'))
	ssh-keygen -s $(CADIR)/$(HOSTCA) -I "$(hostname) $(typ) CAv1" -h -n $(hostname) $@

$(HOSTCA):
	ssh-keygen -t ed25519 -f $@

$(HOSTDIR):
	install -dm755 $@

$(HOSTNAMES): $(HOSTCA)
	install -dm755 $(HOSTDIR)/$<
	ssh-keygen -q -N "$@.$(TLD) hostkey" -t ed25519 -f $(HOSTDIR)/$</$@
	ssh-keygen -s $< -I "$(TLD) CAv1" -h -n $@.$(TLD) $(HOSTDIR)/$</$@.pub

clean:
	rm -fr $(CADIR) $(HOSTDIR)
