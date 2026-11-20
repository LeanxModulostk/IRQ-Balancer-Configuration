# IRQ Kernel Sync

![](https://i.ibb.co/kyK9jhg/1718764307752.png)

Keeps `msm_irqbalance.conf` in sync with your kernel. IRQ IDs usually change when you switch kernels, and they stop matching the ones set in msm_irqbalance.conf.

**English** · [Español](#español)

## Details
- The msm_irqbalance.conf file contains PRIO and IGNORED_IRQ

- **PRIO** defines the priority or availability of each CPU core for interrupt (IRQ) balancing.

What do the values mean?
• 1: The core is enabled and can receive and process hardware interrupts.
• 0: The core is banned (no interrupts should be scheduled or sent to that CPU).

- Common example
• PRIO=1,1,1,1,0,0,0,0:
 • The first 4 cores (0,1,2,3) have value 1 and do handle interrupts.
 • The last 4 cores (4,5,6,7) have value 0 and receive no interrupts, which frees them from kernel overhead so they can be dedicated exclusively to heavy processing tasks or games.

- **IGNORED_IRQ** The IDs listed here ignore the PRIO setting

- **Some IRQs may stay on banned cores: the daemon does not move all of them.**

## What it does
- **Finds the config for you**: checks the path used by the daemon's init script, the usual locations (`/vendor/etc`, `/odm/etc`, `/product/etc`, `/system_ext/etc`, `/system/etc`, `/my_*`) and, as a last resort, searches the device. If the file isn't found, the install is aborted.
- **Replaces it systemless**: every copy found is overridden by the module; nothing is written to your real partitions. Mounting is left to your metamodule / NoMount.
- **Syncs the IRQs**: reads `/proc/interrupts` and writes the IDs of `arch_timer`, `arm-pmu` and `arch_mem_timer` into `IGNORED_IRQ=`. Other lines of the original file are kept.
- **WebUI**: edit `PRIO=` per CPU core with toggles or raw text, save, apply by restarting only the daemon (no phone reboot, although your device may need one).
- **GPU & display tweak** (optional, from the WebUI): adds the `kgsl` and `msm_drm` IRQs to `IGNORED_IRQ=` so the balancer doesn't move them; one tap to revert. [link](https://review.lineageos.org/c/LineageOS/android_device_motorola_sm6150-common/+/370438)
- **SELinux label fix**: the daemon needs the `vendor_configs_file` label on the config; the module re-applies it on every boot and restarts the daemon if it is stuck.
- **Smart updates**: reinstalling keeps the `PRIO=` you set; a fresh install starts with `PRIO=1,1,1,1,0,0,0,0`.

## Requirements
- Magisk 20.4+ or KernelSU/APatch
- WebUI: KernelSU, [WebUI X](https://github.com/MMRLApp/WebUI-X-Portable) or KSUWebUIStandalone

## Usage
1. Flash the zip and reboot.
2. Open the module's WebUI → set `PRIO=` (one value per core, `cpu0 … cpuN`) → **Save & apply**.
3. After a kernel change, reinstall the module to re-sync the IRQs.

## Support
- Telegram: [@modulostk](https://t.me/modulostk)
- [GitHub](https://github.com/LeanxModulostk/IRQ-Balancer-Configuration)

## Extras
- Donations: [PayPal](https://www.paypal.me/LeanHijosdesusMadres) - [LiberaPay](https://liberapay.com/LeanHijosdesusMadres) - [Ko-fi](https://ko-fi.com/leantupapi) - [Binance](https://app.binance.com/qr/dplk7b28e9c123ff4e378b472505b0adba63) - [SociaBuzz](https://sociabuzz.com/leanhijosdesusmadres/support) - [More](https://t.me/modulemagiskChiase/4846)

---

## Español

Mantiene `msm_irqbalance.conf` sincronizado con tu kernel, al cambiar de kernel suelen cambiar los IDs IRQ y deja de coincidir con los establecidos en msm_irqbalance.conf

### Detalles
- En el archivo msm_irqbalance.conf existen PRIO y IGNORED_IRQ

- **PRIO** define la prioridad o disponibilidad de cada núcleo de la CPU para el balanceo de interrupciones (IRQs).

¿Qué significan los valores?
• 1: El núcleo está habilitado y puede recibir y procesar interrupciones de hardware.
• 0: El núcleo está prohibido (significa que no se deben programar ni enviar interrupciones a ese CPU).

- Ejemplo común
• PRIO=1,1,1,1,0,0,0,0:
 • Los primeros 4 núcleos (0,1,2,3) tienen valor 1 y sí gestionan interrupciones.
 • Los últimos 4 núcleos (4,5,6,7) tienen valor 0 y no reciben interrupciones, liberándolos así de la sobrecarga del kernel para que se dediquen exclusivamente a tareas pesadas de procesamiento o juegos.

- **IGNORED_IRQ** Los IDs que aparecen acá ignoran la configuración de PRIO

- **Algunas IRQs pueden seguir en núcleos prohibidos: el demonio no las mueve todas.**

### Qué hace
- **Encuentra el archivo solo**: revisa la ruta que usa el init del demonio, las ubicaciones habituales (`/vendor/etc`, `/odm/etc`, `/product/etc`, `/system_ext/etc`, `/system/etc`, `/my_*`) y, como último recurso, lo busca en el dispositivo. Si no existe, la instalación se cancela.
- **Lo reemplaza sin tocar el sistema (systemless)**: cada copia encontrada se sobrescribe desde el módulo. El montaje lo hace tu módulo meta / NoMount.
- **Sincroniza las IRQs**: lee `/proc/interrupts` y escribe los IDs de `arch_timer`, `arm-pmu` y `arch_mem_timer` en `IGNORED_IRQ`. Las demás líneas del archivo original se conservan.
- **WebUI**: edita `PRIO` por núcleo con interruptores o texto, guarda, aplica reiniciando solo el demonio (sin reiniciar el teléfono, quizás en su dispositivo necesite reiniciar).
- **Ajuste de GPU y pantalla** (opcional, desde la WebUI): añade las IRQs de `kgsl` y `msm_drm` a `IGNORED_IRQ` para que el balanceador no las mueva; se revierte con un toque. [link](https://review.lineageos.org/c/LineageOS/android_device_motorola_sm6150-common/+/370438)
- **Corrección de etiqueta SELinux**: el demonio necesita la etiqueta `vendor_configs_file` en el archivo; el módulo la reaplica en cada arranque y reinicia el demonio si queda atascado.
- **Actualizaciones inteligentes**: al reinstalar se mantiene tu `PRIO`; en una instalación nueva empieza con `PRIO=1,1,1,1,0,0,0,0`.

### Requisitos
- Magisk 20.4+ o KernelSU/APatch
- WebUI: KernelSU, [WebUI X](https://github.com/MMRLApp/WebUI-X-Portable) o KSUWebUIStandalone

### Uso
1. Flashea el zip y reinicia.
2. Abre la WebUI del módulo → ajusta `PRIO=` (un valor por núcleo, `cpu0 … cpuN`) → **Guardar y aplicar**.
3. Si cambias de kernel, reinstala el módulo para re-sincronizar las IRQs.

### Soporte
- Telegram: [@modulostk](https://t.me/modulostk)
- [GitHub](https://github.com/LeanxModulostk/IRQ-Balancer-Configuration)

### Extras
- Donaciones: [PayPal](https://www.paypal.me/LeanHijosdesusMadres) - [LiberaPay](https://liberapay.com/LeanHijosdesusMadres) - [Ko-fi](https://ko-fi.com/leantupapi) - [Binance](https://app.binance.com/qr/dplk7b28e9c123ff4e378b472505b0adba63) - [SociaBuzz](https://sociabuzz.com/leanhijosdesusmadres/support) - [More](https://t.me/modulemagiskChiase/4846)

## Special Thanks / Agradecimientos
• [Zackptg5 for the MMT-Ex template](https://github.com/Zackptg5)

• [Topjohnwu for making Magisk](https://github.com/topjohnwu)
