# -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:ft=tcl:et:sw=4:ts=4:sts=4

default categories          {sysutils}
default platforms           {darwin}
default license             {BSD}
default maintainers         {admin}
default supported_archs     {noarch}
default homepage            {https://www.macports.org}
default archive_sites       {}
default master_sites        {}
default distfiles           {}

use_configure               no
build {}
pre-destroot {
    xinstall -d ${destroot}/Library/LaunchDaemons
}
destroot {}
post-destroot {
    foreach f [glob -nocomplain -tails -directory ${destroot}/Library/LaunchDaemons net.macports.*.plist] {
        ln -s ${f} ${destroot}/Library/LaunchDaemons/org.macports.${f}
    }
}
default destroot.keepdirs   {${destroot}${prefix}/share}

default livecheck.type      {none}

options PlistBuddy
default PlistBuddy          {/usr/libexec/PlistBuddy}
