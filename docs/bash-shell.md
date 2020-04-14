# Preparing the Bash shell for effective SolaKube command execution

At this point SolaKube is expected to be run from your home folder (as opposed to be installed into /opt or similar system location)

If you need to issue SolaKube commands repeatedly, you are better off having a command alias created for the sk script.

In your interactive Bash shell:

alias sk=/path/to/solakube/sk

After this, you can execute SolaKube sk commands easily from any folder.

In case you work with SolaKube often, it may make sense to extend your .bashrc with a function with a short name that quickly defines the alias for you and possibly makes other preparations for your CLI session.

See templates/bashrc-shell-setup-shorthand.txt for a sample.

Alternatively, you may add the scripts subfolder to your PATH. 
 