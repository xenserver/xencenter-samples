# XenCenter Plug-in Examples

[XenCenter](https://docs.xenserver.com/en-us/xencenter)
is the management console used with [XenServer](https://www.xenserver.com/),
a leading open source virtualization platform.
From XenCenter you can natively perform common operations such as starting,
stopping and migrating a VM, and administering the XenServer resource pool
which hosts those VMs. While these common operations are seemlessly handled,
there are times when external operations are needed. To address those
scenarios, XenCenter implements a plug-in architecture.

XenCenter has plug-in capabilities which allow you to add custom menu items or
even whole tabs to the XenCenter window. You might do this as an ISV to integrate
your own product with XenCenter, or as an end-user to integrate with your
company's existing inventory management, for example.

This repository contains examples of how to create a XenCenter plug-in written
in various languages and build an installer for it.

## Documentation

[XenCenter Plug-in Specification Guide](https://docs.xenserver.com/en-us/xenserver/8/developer/xencenter-plugin-specification)
contains the complete specification for developing XenCenter plug-ins.

A walk-through of the examples and instructions on how to compile the plug-in
installers are available in the [docs](docs/README.md) pages.

## Issues

Questions related to these samples can be posted on this repo's
[issues](https://github.com/xenserver/xencenter-samples/issues) page.

## License

This code is licensed under the BSD 2-Clause license. Please see the
[LICENSE](LICENSE) file for more information. Excepted are the jquery libraries
used with the JavaScript sample, which are licensed under the [MIT][1] and
[GPL2][2] licenses.

[1]: https://opensource.org/licenses/MIT
[2]: http://www.gnu.org/licenses/old-licenses/gpl-2.0.html
