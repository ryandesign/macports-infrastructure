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
default startupitem.uniquename \
                            {${startupitem.name}}

use_configure               no

build {}

pre-destroot {
    xinstall -d ${destroot}/Library/${startupitem.location}
}

destroot {}

# Add this post-destroot after any the port might declare, since we want to
# find any plists they might have installed.
port::register_callback net.macports.add_post_destroot
proc net.macports.add_post_destroot {} {
    post-destroot {
        foreach f [glob -nocomplain -tails -directory ${destroot} Library/${startupitem.location}/net.macports.*.plist] {
            set f /${f}
            set uniquename [file rootname [file tail ${f}]]
            xinstall -d ${destroot}${prefix}/etc/${startupitem.location}/${uniquename}
            # Technically this is only needed if ${startupitem.install} is no.
            ln -s ${f} ${destroot}${prefix}/etc/${startupitem.location}/${uniquename}/${uniquename}.plist
        }
    }
}

default destroot.keepdirs   {${destroot}${prefix}/share}

default livecheck.type      {none}

options PlistBuddy
default PlistBuddy          {/usr/libexec/PlistBuddy}
