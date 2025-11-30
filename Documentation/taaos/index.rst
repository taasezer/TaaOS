TaaOS (Developer-Optimized Linux)
==================================

TaaOS is a custom Linux distribution built directly into this kernel source tree.

Documentation
-------------

.. toctree::
   :maxdepth: 2

   overview
   building
   features
   customization

Quick Links
-----------

* :doc:`overview` - TaaOS overview and architecture
* :doc:`building` - How to build TaaOS kernel
* :doc:`features` - TaaOS-specific features
* :doc:`customization` - Customizing TaaOS

External Documentation
----------------------

Full TaaOS documentation is located in ``taaos/docs/``:

* ``taaos/README.md`` - Main project README
* ``taaos/docs/BUILD_GUIDE.md`` - Complete build instructions
* ``taaos/docs/QUICKSTART.md`` - Quick start guide
* ``taaos/docs/taaos-structure.md`` - Technical architecture
* ``taaos/docs/ROADMAP.md`` - Development roadmap

TaaOS Tools
-----------

* **TaaPac** - Package manager (``taaos/taapac/``)
* **TaaBuild** - Build system (``taaos/taapac/``)
* **TaaTheme** - Theme engine (``taaos/taatheme/``)
* **TaaOS Guardian** - Security monitor (``taaos/security/``)
* **ISO Builder** - Bootable image creator (``taaos/iso/``)

Quick Build
-----------

::

    # Use TaaOS kernel configuration
    make taaos_defconfig
    
    # Build kernel
    ./scripts/taaos-build-kernel.sh
    
    # Or build manually
    make -j$(nproc)
    sudo make modules_install install

Branding
--------

TaaOS modifications include:

* Custom kernel version string (``-taaos``)
* Rosso Corsa ASCII art boot banner
* TaaOS-specific messages during boot
* Default configuration optimized for developers
* Integrated build scripts

Performance
-----------

* Boot time: <3 seconds (target)
* I/O Scheduler: BFQ (optimized for SSD/NVMe)
* Timer frequency: 1000 Hz (low latency)
* Preemption: Full preemptive kernel
* Optimization: -O3 with -march=native

License
-------

GPL-2.0 (same as Linux kernel)
