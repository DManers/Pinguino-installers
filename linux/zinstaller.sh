#!/bin/bash

# ----------------------------------------------------------------------
# description:		Pinguino IDE Installation Script
# author:			regis blanchot <rblanchot@gmail.com>
# first release:	25-04-2014
# last release:		05-03-2015
# ----------------------------------------------------------------------

DOWNLOAD=1
INSTALL=1
INTERFACE=
ASKPWAGAIN=1

DLDIR=https://sourceforge.net/projects/pinguinoide/files/linux/

# FUNCTIONS ------------------------------------------------------------

function fetch {
    # Download a package from Pinguino's SourceForge account
    wget --quiet --timestamping ${DLDIR}/$1.deb | \
    zenity  --progress \
            --title="Pinguino IDE Installer" \
            --text="Checking and downloading $1 package" \
            --height=250 --width=500 \
            --pulsate --auto-close
            
    if [ $? == 1 ]; then
        exit 1
    fi
}

function install {
    # Install DEB package
    sudo dpkg --install --force-overwrite $1.deb | \
    zenity  --progress \
            --title='Pinguino IDE Installer' \
            --text='Installing $1 package' \
            --height=250 --width=500 \
            --pulsate --auto-close

    if [ $? == 1 ]; then
        exit 1
    fi
    
    sudo apt-get install -f > /dev/null
}

# ARCHITECTURE ? -------------------------------------------------------

if [ `uname -m` == "armv6l" ]; then
    ARCH=RPi
    ARCHTXT="Raspberry Pi"
elif [ `uname -m` == "armv7l" ]; then
    ARCH=RPi
    ARCHTXT="Raspberry Pi 2"
elif [ `uname -m` == "x86_64" ]; then
    ARCH=64
    ARCHTXT="${ARCH}-bit GNU/Linux."
else
    ARCH=32
    ARCHTXT="${ARCH}-bit GNU/Linux."
fi

# PROCEED ? ------------------------------------------------------------

wget --quiet --timestamping https://sourceforge.net/projects/pinguinoide/files/changelog
CHANGELOG=$(cat changelog | head -n 5)

zenity  --question \
        --height=250 --width=500 \
        --title="Pinguino IDE Installer" \
        --text "
<span color=\"red\"><b><big>Pinguino IDE Installer</big></b></span>

<span>Author:\tRégis Blanchot</span>
<span>Contact:\trblanchot@pinguino.cc</span>
<span>Version:\t20150305</span>
<span>Host:\t<b>${ARCHTXT}</b></span>

<span><b>Last changes :</b></span>

<span font=\"monospace 8\">${CHANGELOG}</span>

<span><b>Do you want to proceed ?</b></span>"

if [ $? == 1 ]; then
    exit 1
fi

# SUPERUSER ? ----------------------------------------------------------

while [ $ASKPWAGAIN == 1 ]; do

PASSWORD=$(zenity --password \
                  --height=250 --width=500 \
                  --title="Pinguino IDE Installer")

if [ ${?} != 0 ]; then
    exit 1
fi

if [ -z ${PASSWORD} ] || [ ! sudo -kSp '' [ 1 ] <<<"${PASSWORD}" 2>/dev/null ]; then
    zenity  --question \
            --height=250 --width=500 \
            --title="Pinguino IDE Installer" \
            --text "
            <span color=\"red\"><b><big>Invalid password</big></b></span>

            <span>Would you like to cancel the installation ?</span>"
    if [ $? == 0 ]; then
        exit 1
    else
        ASKPWAGAIN=1
    fi
else
    ASKPWAGAIN=0
fi

done

echo -e $PASSWORD | sudo -S -s

# COMPILERS ? ----------------------------------------------------------

if [ $ARCH == RPi ]; then

    zenity  --question \
            --height=250 --width=500 \
            --title="Pinguino IDE Installer" \
            --text="Do you want to install the 8-bit compiler ?"

    case $? in
        0) C8=NO  C32=NO  ;;
        1) C8=YES C32=NO  ;;
    esac

else

    answer=$(zenity  --list \
            --title="Pinguino IDE Installer" \
            --height=250 --width=500 \
            --radiolist \
            --text "Which compiler(s) do you want to install ?" \
            --column "Select..." --column 'Compiler(s)' \
    TRUE "none of them" \
    FALSE "the  8-bit (PIC18F)  compiler only" \
    FALSE "the 32-bit (PIC32MX) compiler only" \
    FALSE "both 8- and 32-bit compilers")

    if [ $? != 0 ]; then
        exit 1
    fi
    
    case $answer in
        0) C8=NO  C32=NO  ;;
        1) C8=YES C32=NO  ;;
        2) C8=NO  C32=YES ;;
        3) C8=YES C32=YES ;;
    esac

fi

# INTERFACE ? ----------------------------------------------------------

if [ ${INTERFACE} ]; then

    answer=$(zenity  --list \
            --title="Pinguino IDE Installer" \
            --height=250 --width=500 \
            --radiolist \
            --text "Which graphical interface do you want to install ?" \
            --column "Select..." --column 'Interface' \
    FALSE "Tkinter-based IDE (simple and light)" \
    TRUE "Qt4-based IDE")

    if [ $? != 0 ]; then
        exit 1
    fi
    
    case $answer in
        1) TK=YES ;;
        *) TK=NO  ;;
    esac

else

    TK=NO

fi

# DOWNLOAD PACKAGES ----------------------------------------------------

if [ ${DOWNLOAD} ]; then
    
    if [ "$TK" == "YES" ]; then
        fetch pinguino-ide-tk
    else
        fetch pinguino-ide
    fi
    
    fetch pinguino-libraries

    if [ "$C8" == "YES" ]; then
        fetch pinguino-linux${ARCH}-sdcc-mpic16
    fi

    if [ "$C32" == "YES" ]; then
        fetch pinguino-linux${ARCH}-gcc-mips-elf
    fi

fi

# INSTALL PACKAGES -----------------------------------------------------

if [ ${INSTALL} ]; then

    if [ "$C8" == "YES" ]; then
        install pinguino-linux${ARCH}-sdcc-mpic16
    fi

    if [ "$C32" == "YES" ]; then
        install pinguino-linux${ARCH}-gcc-mips-elf
    fi

    install pinguino-libraries

    if [ "$TK" == "YES" ]; then
        install pinguino-ide-tk
    else
        install pinguino-ide
    fi

# POST INSTALL ---------------------------------------------------------

python /usr/share/pinguino-11/post_install.py

fi

# INSTALLATION COMPLETE ------------------------------------------------

if zenity  --question \
        --height=250 --width=500 \
        --title="Pinguino IDE Installer" \
        --text="Installation complete.\n\rDo you want to launch the IDE ?"
then
    python /usr/share/pinguino-11/pinguino.py
fi

