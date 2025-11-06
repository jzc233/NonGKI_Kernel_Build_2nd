| Device | Location | Codename | Kernel/Author/Name | OS | Android | Pack Method | KernelSU | SuSFS | Hook | KPM | Re:Kernel | BBG | Status |  
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|  
| Oneplus 8 | All | instantnoodle | [4.19/ppajda/XTD](https://github.com/ppajda/android_kernel_oneplus_sm8250) | Oxygen OS 13.1 | 13 | AnyKernel3 | rsuntk | ✅ | Normal | ❌ | ❌ | ❌ | Stable |  
| Xiaomi Mix2s | All | polaris | [4.9/Evolution-X-Devices/sdm845](https://github.com/Evolution-X-Devices/kernel_xiaomi_sdm845) | Evolution X 10.X | 15 | AnyKernel3 | SukiSU(U) | ✅ | Tracepoint | ✅ | ✅ | ✅ | Stable |   
| Redmi K20 Pro | All | raphael | [4.14/SOVIET-ANDROID/SOVIET-STAR-OSS](https://github.com/SOVIET-ANDROID/kernel_xiaomi_raphael) | Based-AOSP | 15 | AnyKernel3 | rsuntk | ✅ | Syscall | ❌ | ❌ | ❌ | Stable |  
| Samsung Note 10 Plus | EU | d2s | [4.14/Ocin4ever/ExtremeKernel](https://github.com/Ocin4ever/ExtremeKernel) | OneUI 7 | 15 | AnyKernel3 | SukiSU(U) | ✅ | Tracepoint | ❌ | ❌ | ❌ | Stable |  
| Xiaomi 11 | All | venus | [5.4/kamikaonashi/venus](https://github.com/kamikaonashi/kernel_xiaomi_venus) | Evolution X 11.X | 16 | AnyKernel3 | SukiSU(U) | ✅ | Tracepoint | ✅ | ✅ | ❌ | Stable |  
| Xiaomi Mix2s | All | polaris | [4.19/duckyduckG/sdm845_419](https://github.com/duckyduckG/android_kernel_xiaomi_sdm845_419) | Based AOSP | 15 | AnyKernel3 | SukiSU(U) | ✅ | Tracepoint | ❌ | ❌ | ❌ | Testing |  
| Redmi Note 10 Pro | CN | chopin | [4.14/ChopinKernels/android_T](https://github.com/ChopinKernels/android_kernel_chopin_android_T) | MIUI | 13 | AnyKernel3 | SukiSU(U) | ❌ | Normal | ❌ | ❌ | ❌ | Testing |  
| Smartisan U3 Pro | CN | osborn | [4.4/anrui2032/LineageOS](https://github.com/anrui2032/android_kernel_smartisan_sdm660) | Lineage OS 18 | 11 | AnyKernel3 | SukiSU(U) | ❌ | Normal | ❌ | ❌ | ❌ | Stable |  
| Redmi Note 10 Pro | INT | sweet | [4.14/negrroo/Lawrun_sm6150](https://github.com/negrroo/LawRun_xiaomi_sm6150) | MIUI | 13 | AnyKernel3 | rsuntk | ❌ | Normal | ❌ | ❌ | ❌ | Testing |  
| Redmi 8 | All | olive | [4.19/blazey66/sdm439-4.19](https://github.com/blazey66/android_kernel_xiaomi_sdm439-4.19) | Based-AOSP | 15 | AnyKernel3 | SukiSU(U) | ✅ | Syscall | ✅ | ✅ | ✅ | Stable |  
| Redmi Note 7 | CN | lavender | [4.19/pix106/southwest](https://github.com/pix106/android_kernel_xiaomi_southwest-4.19) | Based-AOSP | 15 | AnyKernel3 | SukiSU(U) | ✅ | Syscall | ❌ | ❌ | ❌ | Stable |  
| Smartisan U3 Pro | CN | osborn | [4.4/MoKee/smartisan_sdm660](https://github.com/MoKee/android_kernel_smartisan_sdm660) | Mokee | 7.1.1 | AnyKernel3 | Offical | ❌ | Normal | ❌ | ❌ | ❌ | Testing |  
| Samsung Note 10 | EU | d1 | [4.14/Ocin4ever/ExtremeKernel](https://github.com/Ocin4ever/ExtremeKernel) | OneUI 7 | 15 | AnyKernel3 | SukiSU(U) | ✅ | Tracepoint | ❌ | ❌ | ❌ | Stable |  
| Redmi Note 11 Pro 5G | INT | veux | [5.4/dev-sm6375/Nebula](https://github.com/dev-sm6375/kernel_xiaomi_sm6375) | Based AOSP | 16 | AnyKernel3 | SukiSU(U) | ✅ | Syscall | ✅ | ❌ | ❌ | Stable |  
| Oneplus 8 | All | instantnoodle | [4.19/toraidl/los](https://github.com/toraidl/android_kernel_oneplus_sm8250_los) | Color OS 15 | 15 | AnyKernel3 | SukiSU(U) | ✅ | Syscall | ✅ | ❌ | ✅ | Stable |  

**English**:  
- OnePlus 8 OxygenOS/ColorOS 13.1 has been tested and can be used on the OnePlus 8, 8T, 8 Pro and 9R.
- Xiaomi Mix 2S EvolutionX 10 has been backported to Cgroup V2 (UID and Freezer), Binder (5.15-android13), LZ4 (Updated to 1.10.0, LZ4K, LZ4K_OPLUS, LZ4KD), Zstd (Updated to 1.5.7).
- Samsung Note 10 Plus is compatible with the Exynos 9850 processor for the EU region. Do not flash this firmware onto Qualcomm-based devices.
- Redmi 8 is also available for 7A, 8, 8A and 8A Dual.

**Chinese**:  
- 一加 8 OxygenOS/ColorOS 13.1 经测试8、8T、8 Pro、9R 都可用
- 小米 Mix2s EvolutionX 10 已移植Cgroup V2 (UID 和 Freezer)、Binder (5.15-android13)、LZ4（更新至1.10.0、LZ4K、LZ4K_OPLUS、LZ4KD）以及Zstd（更新至1.5.7）
- 三星 Note 10+ 适配处理器为猎户座9850，为欧盟地区版本，高通版本请勿刷入
- 红米8 同样适用于 7A、8、8A 以及 8A Dual
