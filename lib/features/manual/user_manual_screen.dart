import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';

class UserManualScreen extends StatelessWidget {
  const UserManualScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 14),
              sliver: SliverList.list(
                children: [
                  _ManualHeader(onBack: () => Navigator.of(context).pop()),
                  const SizedBox(height: 34),
                  Text(
                    context.translate(
                      'Follow these steps to add, connect, and monitor your BMS.',
                      'Ikuti langkah berikut untuk menambah, menghubungkan, dan memantau BMS.',
                    ),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _ManualSection(
                    icon: Icons.add_link_rounded,
                    title: context.translate(
                      'Add a BMS Device',
                      'Tambah Perangkat BMS',
                    ),
                    steps: [
                      _ManualStep(
                        number: 1,
                        title: context.translate(
                          'Enable access',
                          'Aktifkan akses',
                        ),
                        description: context.translate(
                          'Turn on Bluetooth and allow Nearby Devices and '
                              'Camera permissions when requested.',
                          'Nyalakan Bluetooth dan izinkan akses Perangkat '
                              'Terdekat serta Kamera saat diminta.',
                        ),
                      ),
                      _ManualStep(
                        number: 2,
                        title: context.translate(
                          'Open Add Device',
                          'Buka Tambah Perangkat',
                        ),
                        description: context.translate(
                          'From the home screen, tap Add Device. Scan the QR '
                              'code containing the BMS Bluetooth MAC address.',
                          'Dari layar utama, ketuk Tambah Perangkat. Pindai '
                              'kode QR yang berisi alamat MAC Bluetooth BMS.',
                        ),
                      ),
                      _ManualStep(
                        number: 3,
                        title: context.translate(
                          'Scan nearby devices',
                          'Pindai perangkat terdekat',
                        ),
                        description: context.translate(
                          'If a QR code is unavailable, tap the Bluetooth '
                              'scan button and select the correct BMS.',
                          'Jika kode QR tidak tersedia, ketuk tombol pindai '
                              'Bluetooth lalu pilih BMS yang benar.',
                        ),
                      ),
                      _ManualStep(
                        number: 4,
                        title: context.translate(
                          'Save the device',
                          'Simpan perangkat',
                        ),
                        description: context.translate(
                          'Confirm the detected device. It will appear in '
                              'your saved-device list.',
                          'Konfirmasi perangkat yang terdeteksi. Perangkat akan '
                              'muncul dalam daftar perangkat tersimpan.',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _ManualSection(
                    icon: Icons.monitor_heart_outlined,
                    title: context.translate(
                      'Monitor a Device',
                      'Pantau Perangkat',
                    ),
                    steps: [
                      _ManualStep(
                        number: 5,
                        title: context.translate('Select the BMS', 'Pilih BMS'),
                        description: context.translate(
                          'Tap Monitoring Device on the home screen, then '
                              'choose a device from the saved list.',
                          'Ketuk Pemantauan Perangkat pada layar utama, lalu '
                              'pilih perangkat dari daftar tersimpan.',
                        ),
                      ),
                      _ManualStep(
                        number: 6,
                        title: context.translate(
                          'Wait for connection',
                          'Tunggu koneksi',
                        ),
                        description: context.translate(
                          'Keep the BMS nearby and advertising. Wait for the '
                              'status to show Connected, or tap Retry.',
                          'Pastikan BMS berada di dekat dan sedang mengirim '
                              'sinyal. Tunggu status Terhubung atau ketuk Coba lagi.',
                        ),
                      ),
                      _ManualStep(
                        number: 7,
                        title: context.translate(
                          'Read pack data',
                          'Baca data paket',
                        ),
                        description: context.translate(
                          'The Pack tab shows state of charge, voltage, '
                              'current, temperature, status, and error logs. '
                              'Each active error-code bit is shown as its own '
                              'row with a description.',
                          'Tab Paket menampilkan tingkat daya, tegangan, arus, '
                              'suhu, status, dan log kesalahan. Setiap bit kode '
                              'kesalahan yang aktif ditampilkan sebagai baris '
                              'tersendiri beserta deskripsinya.',
                        ),
                      ),
                      _ManualStep(
                        number: 8,
                        title: context.translate(
                          'Read cell data',
                          'Baca data sel',
                        ),
                        description: context.translate(
                          'Open the Cell tab to see maximum, minimum, and '
                              'difference statistics plus every cell reported '
                              'by the BMS. Cell voltages are shown in volts, '
                              'and the displayed cell count adjusts '
                              'automatically. Values below 0.500 V are not '
                              'counted as series cells.',
                          'Buka tab Sel untuk melihat statistik maksimum, '
                              'minimum, selisih, dan setiap sel yang dilaporkan '
                              'BMS. Tegangan sel ditampilkan dalam volt, dan '
                              'jumlah sel menyesuaikan secara otomatis. Nilai '
                              'di bawah 0,500 V tidak dihitung sebagai sel seri.',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const _IndicatorSection(),
                  const SizedBox(height: 14),
                  _ManualSection(
                    icon: Icons.build_outlined,
                    title: context.translate('Device Tools', 'Alat Perangkat'),
                    steps: [
                      _ManualStep(
                        number: 9,
                        title: context.translate(
                          'Inspect raw Bluetooth data',
                          'Periksa data Bluetooth mentah',
                        ),
                        description: context.translate(
                          'Enable Show Raw JSON in App Settings. After '
                              'connecting, tap Raw JSON to inspect the '
                              'unprocessed messages received from the BMS.',
                          'Aktifkan Tampilkan JSON Mentah di Pengaturan '
                              'Aplikasi. Setelah terhubung, ketuk JSON Mentah '
                              'untuk memeriksa pesan asli yang diterima dari BMS.',
                        ),
                      ),
                      _ManualStep(
                        number: 10,
                        title: context.translate(
                          'Record monitoring data',
                          'Rekam data pemantauan',
                        ),
                        description: context.translate(
                          'Enable Record data in App Settings before '
                              'connecting. Recording starts when Bluetooth '
                              'connects and stops when it disconnects. The CSV '
                              'file is saved in Download/ELBI Smart BMS, with '
                              'cell columns matching the monitored BMS.',
                          'Aktifkan Rekam data di Pengaturan Aplikasi sebelum '
                              'menghubungkan. Perekaman dimulai saat Bluetooth '
                              'terhubung dan berhenti saat terputus. File CSV '
                              'disimpan di Download/ELBI Smart BMS, dengan '
                              'kolom sel sesuai BMS yang dipantau.',
                        ),
                      ),
                      _ManualStep(
                        number: 11,
                        title: context.translate(
                          'Choose the battery type',
                          'Pilih jenis baterai',
                        ),
                        description: context.translate(
                          'Tap the gear icon on the monitoring page, then '
                              'select LFP, NMC, or LTO. The preset fills the '
                              'supported protection, delay, temperature, '
                              'balancing, and sleep values.',
                          'Ketuk ikon roda gigi pada halaman pemantauan, lalu '
                              'pilih LFP, NMC, atau LTO. Preset akan mengisi '
                              'nilai proteksi, jeda, suhu, penyeimbangan, dan '
                              'waktu tidur yang didukung.',
                        ),
                      ),
                      _ManualStep(
                        number: 12,
                        title: context.translate(
                          'Review and save parameters',
                          'Periksa dan simpan parameter',
                        ),
                        description: context.translate(
                          'Review every value before saving. Current limits, '
                              'battery capacity, and shunt resistance are not '
                              'changed by a preset. Delay values are shown in '
                              'seconds, and voltage settings are shown in '
                              'volts. UVP and OVP must stay inside the strict '
                              'range shown for the selected chemistry, and '
                              'battery over-temperature must be below 60°C. '
                              'Tap Save Parameters to send the final values to '
                              'the connected BMS.',
                          'Periksa setiap nilai sebelum menyimpan. Batas arus, '
                              'kapasitas baterai, dan resistansi shunt tidak '
                              'diubah oleh preset. Nilai jeda ditampilkan dalam '
                              'detik dan pengaturan tegangan ditampilkan dalam '
                              'volt. UVP dan OVP harus berada dalam rentang '
                              'ketat yang ditampilkan untuk jenis baterai, dan '
                              'suhu berlebih baterai harus di bawah 60°C. Ketuk '
                              'Simpan Parameter untuk mengirim nilai akhir ke '
                              'BMS yang terhubung.',
                        ),
                      ),
                      _ManualStep(
                        number: 13,
                        title: context.translate(
                          'Use demo mode',
                          'Gunakan mode demo',
                        ),
                        description: context.translate(
                          'Open the monitoring demo to pause or resume data, '
                              'create a new sample, simulate a fault, or simulate '
                              'a low battery.',
                          'Buka demo pemantauan untuk menjeda atau melanjutkan '
                              'data, membuat sampel baru, menyimulasikan gangguan, '
                              'atau menyimulasikan baterai lemah.',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const _TroubleshootingSection(),
                  const SizedBox(height: 31),
                  const Text(
                    AppTheme.brandName,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.accent, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualHeader extends StatelessWidget {
  const _ManualHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(6),
            child: const SizedBox.square(
              dimension: 27,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
        Expanded(
          child: Text(
            context.translate('User Manual', 'Panduan Pengguna'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 27),
      ],
    );
  }
}

class _ManualSection extends StatelessWidget {
  const _ManualSection({
    required this.icon,
    required this.title,
    required this.steps,
  });

  final IconData icon;
  final String title;
  final List<_ManualStep> steps;

  @override
  Widget build(BuildContext context) {
    return _ManualCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(icon: icon, title: title),
          const SizedBox(height: 14),
          for (var index = 0; index < steps.length; index++) ...[
            _StepRow(step: steps[index]),
            if (index < steps.length - 1) const _SectionDivider(),
          ],
        ],
      ),
    );
  }
}

class _IndicatorSection extends StatelessWidget {
  const _IndicatorSection();

  @override
  Widget build(BuildContext context) {
    return _ManualCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.battery_charging_full_rounded,
            title: context.translate('Battery Indicators', 'Indikator Baterai'),
          ),
          const SizedBox(height: 14),
          _IndicatorRow(
            color: const Color(0xFF008447),
            label: context.translate('Normal', 'Normal'),
            description: context.translate(
              'Battery SOC is at least 15% and not charging.',
              'SOC baterai minimal 15% dan baterai tidak sedang diisi.',
            ),
          ),
          const _SectionDivider(),
          _IndicatorRow(
            color: const Color(0xFF0D82F8),
            label: context.translate('Charging', 'Mengisi daya'),
            description: context.translate(
              'Battery current is greater than 0.5 A.',
              'Arus baterai lebih besar dari 0,5 A.',
            ),
          ),
          const _SectionDivider(),
          _IndicatorRow(
            color: const Color(0xFFFF5364),
            label: context.translate('Low', 'Lemah'),
            description: context.translate(
              'Battery SOC is below 15%. This warning takes priority.',
              'SOC baterai di bawah 15%. Peringatan ini menjadi prioritas.',
            ),
          ),
        ],
      ),
    );
  }
}

class _TroubleshootingSection extends StatelessWidget {
  const _TroubleshootingSection();

  @override
  Widget build(BuildContext context) {
    return _ManualCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.support_agent_rounded,
            title: context.translate('Troubleshooting', 'Pemecahan Masalah'),
          ),
          const SizedBox(height: 14),
          _HelpRow(
            title: context.translate(
              'Device is not found',
              'Perangkat tidak ditemukan',
            ),
            description: context.translate(
              'Confirm the BMS is powered, nearby, and advertising. Turn '
                  'Bluetooth off and on, then scan again.',
              'Pastikan BMS menyala, berada di dekat, dan sedang mengirim '
                  'sinyal. Matikan lalu nyalakan Bluetooth dan pindai kembali.',
            ),
          ),
          const _SectionDivider(),
          _HelpRow(
            title: context.translate('Connection fails', 'Koneksi gagal'),
            description: context.translate(
              'Check Nearby Devices permission, close other apps connected '
                  'to the BMS, and tap Retry.',
              'Periksa izin Perangkat Terdekat, tutup aplikasi lain yang '
                  'terhubung ke BMS, lalu ketuk Coba lagi.',
            ),
          ),
          const _SectionDivider(),
          _HelpRow(
            title: context.translate(
              'No monitoring data',
              'Tidak ada data pemantauan',
            ),
            description: context.translate(
              'Keep the monitoring page open and inspect Raw JSON. The BMS '
                  'must send a complete supported JSON payload.',
              'Biarkan halaman pemantauan terbuka dan periksa JSON Mentah. '
                  'BMS harus mengirim payload JSON lengkap yang didukung.',
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualCard extends StatelessWidget {
  const _ManualCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accent, width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accent, size: 21),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step});

  final _ManualStep step;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 25,
          height: 25,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
          child: Text(
            '${step.number}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _HelpRow(title: step.title, description: step.description),
        ),
      ],
    );
  }
}

class _IndicatorRow extends StatelessWidget {
  const _IndicatorRow({
    required this.color,
    required this.label,
    required this.description,
  });

  final Color color;
  final String label;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 25,
          height: 25,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _HelpRow(title: label, description: description),
        ),
      ],
    );
  }
}

class _HelpRow extends StatelessWidget {
  const _HelpRow({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          description,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 11,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 11),
      child: Divider(height: 1, color: Color(0xFFE4E7EA)),
    );
  }
}

class _ManualStep {
  const _ManualStep({
    required this.number,
    required this.title,
    required this.description,
  });

  final int number;
  final String title;
  final String description;
}
