import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'webview_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final _api = ApiService();

  bool _loading = true;
  String? _error;
  String? _content;
  String? _portalUrl;
  String _qrType = 'plain';
  Map<String, dynamic>? _document;
  bool _isUrl = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _processScan();
  }

  bool _isUuid(String s) {
    return RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(s);
  }

  bool _looksLikeEncryptedPayload(String s) {
    return s.length > 80 && !_isUuid(s) && !_isValidUrl(s);
  }

  Future<void> _processScan() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) return;

    final rawValue = args['rawValue'] as String;
    final qrToken = args['qrToken'] as String;
    final isLoggedIn = args['isLoggedIn'] as bool;

    if (_isValidUrl(rawValue) && !_isUuid(rawValue) && !rawValue.contains('/portal/') && !rawValue.contains('/verify?')) {
      _handlePlainQr(rawValue);
      return;
    }

    if (!_isUuid(qrToken) && !_looksLikeEncryptedPayload(rawValue)) {
      if (_isValidUrl(rawValue)) {
        _handlePlainQr(rawValue);
      } else {
        _handlePlainQr(rawValue);
      }
      return;
    }

    try {
      if (_isUuid(qrToken)) {
        final portalResponse = await _api.scanStandardQr(qrToken);

        if (portalResponse.isEncrypted) {
          await _handleEncryptedQr(qrToken, rawValue, isLoggedIn);
          return;
        }

        setState(() {
          _qrType = 'standard';
          _document = portalResponse.document;
          _content = portalResponse.document?.entries
              .map((e) => '${e.key}: ${e.value}')
              .join('\n');
          _loading = false;
        });
        return;
      }

      if (_looksLikeEncryptedPayload(rawValue)) {
        await _handleEncryptedPayload(rawValue, isLoggedIn);
        return;
      }

      _handlePlainQr(rawValue);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _handlePlainQr(String rawValue) {
    setState(() {
      _qrType = 'plain';
      _content = rawValue;
      _isUrl = _isValidUrl(rawValue);
      _loading = false;
    });
  }

  Future<void> _handleEncryptedQr(String qrToken, String rawValue, bool isLoggedIn) async {
    if (!isLoggedIn) {
      setState(() {
        _qrType = 'encrypted';
        _content = rawValue;
        _loading = false;
      });
      return;
    }

    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (auth.token == null || auth.deviceKeys == null) {
      setState(() {
        _error = 'Device not registered. Please login again.';
        _loading = false;
      });
      return;
    }

    try {
      final scanResult = await _api.scanEncryptedQr(
        token: auth.token!,
        qrToken: qrToken,
      );

      await _decryptWithDevice(auth, scanResult.rawEncryptedPayload);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _handleEncryptedPayload(
      String payload, bool isLoggedIn) async {
    if (!isLoggedIn) {
      setState(() {
        _qrType = 'encrypted';
        _content = payload;
        _loading = false;
      });
      return;
    }

    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (auth.token == null || auth.deviceKeys == null) {
      setState(() {
        _error = 'Device not registered. Please login again.';
        _loading = false;
      });
      return;
    }

    await _decryptWithDevice(auth, payload);
  }

  Future<void> _decryptWithDevice(
      AuthProvider auth, String encryptedPayload) async {
    final result = await _api.decryptHash(
      token: auth.token!,
      deviceId: auth.deviceKeys!.deviceId,
      privateKeyPem: auth.deviceKeys!.privateKey,
      encryptedHash: encryptedPayload,
    );

    setState(() {
      _qrType = 'encrypted';
      _portalUrl = result['portal_url'] as String?;
      final document = result['document'];

      if (document is Map<String, dynamic> && document.isNotEmpty) {
        _document = document;
        _content = document.entries
            .map((e) => '${e.key}: ${e.value}')
            .join('\n');
      } else if (result['data'] is String) {
        _content = result['data'] as String;
        _isUrl = _isValidUrl(_content!);
      } else if (_portalUrl != null && _portalUrl!.isNotEmpty) {
        _content = _portalUrl;
        _isUrl = true;
      } else {
        _content = 'Decrypted document available';
      }

      _loading = false;
    });
  }

  bool _isValidUrl(String str) {
    final uri = Uri.tryParse(str);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  void _showOpenUrlSheet(String url) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Open Link',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: Color(0xFF1A1A2E))),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(url,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D6A4F).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.web_rounded,
                      color: Color(0xFF2D6A4F), size: 22),
                ),
                title: const Text('Open in App',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('View inside built-in browser',
                    style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WebViewScreen(url: url),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D6A4F).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.open_in_new_rounded,
                      color: Color(0xFF2D6A4F), size: 22),
                ),
                title: const Text('Open in Browser',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Choose from installed browsers',
                    style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(ctx);
                  _openExternal(url);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A2E)),
          onPressed: () =>
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
        ),
        title: const Text('Scan Result',
            style:
                TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2D6A4F)))
          : _error != null
              ? _buildError()
              : _buildResult(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                  Icons.error_outline, color: Color(0xFFDC2626), size: 40),
            ),
            const SizedBox(height: 24),
            const Text('Scan Failed',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.4),
            ),
            const SizedBox(height: 28),
            if (_error!.contains('Login required') || _error!.contains('login'))
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D6A4F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Login',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context, '/', (route) => false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A2E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Back to Home',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTypeBadge(),
          const SizedBox(height: 20),
          if (_document != null) _buildDocumentCard(),
          if (_content != null && _document == null) _buildContentCard(),
          if (_portalUrl != null && _qrType != 'encrypted') ...[
            const SizedBox(height: 16),
            _buildPortalUrlCard(),
          ],
          if (_isUrl && _content != null && _qrType != 'standard') ...[
            const SizedBox(height: 20),
            _buildVisitButton(),
          ],
          const SizedBox(height: 12),
          _buildScanAgainButton(),
        ],
      ),
    );
  }

  Widget _buildTypeBadge() {
    return Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: _qrType == 'encrypted'
              ? const Color(0xFFFEF3C7)
              : _qrType == 'standard'
                  ? const Color(0xFFD1FAE5)
                  : const Color(0xFFE0E7FF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            _qrType == 'encrypted'
                ? Icons.lock_rounded
                : _qrType == 'standard'
                    ? Icons.description_rounded
                    : Icons.text_snippet_rounded,
            size: 16,
            color: _qrType == 'encrypted'
                ? const Color(0xFFD97706)
                : _qrType == 'standard'
                    ? const Color(0xFF059669)
                    : const Color(0xFF4F46E5),
          ),
          const SizedBox(width: 6),
          Text(
            _qrType == 'encrypted'
                ? 'Encrypted QR'
                : _qrType == 'standard'
                    ? 'Standard Document'
                    : 'Plain Text',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: _qrType == 'encrypted'
                  ? const Color(0xFFD97706)
                  : _qrType == 'standard'
                      ? const Color(0xFF059669)
                      : const Color(0xFF4F46E5),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildDocumentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2D6A4F).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.description_rounded,
                color: Color(0xFF2D6A4F), size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Document Details',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF1A1A2E))),
        ]),
        const Divider(height: 28),
        ..._document!.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                  width: 120,
                  child: Text(_formatKey(e.key),
                      style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ),
                Expanded(
                  child: Text(e.value?.toString() ?? '',
                      style: const TextStyle(
                          color: Color(0xFF1A1A2E),
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                ),
              ]),
            )),
      ]),
    );
  }

  Widget _buildContentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2D6A4F).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
                _isUrl
                    ? Icons.link_rounded
                    : Icons.text_snippet_rounded,
                color: Color(0xFF2D6A4F), size: 20),
          ),
          const SizedBox(width: 12),
          Text(_qrType == 'plain' ? 'QR Content' : 'Decrypted Content',
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF1A1A2E))),
        ]),
        const Divider(height: 24),
        _isUrl
            ? GestureDetector(
                onTap: () => _showOpenUrlSheet(_content!),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D6A4F).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF2D6A4F).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _content!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF2D6A4F),
                            decoration: TextDecoration.underline,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.open_in_new_rounded,
                          color: const Color(0xFF2D6A4F).withValues(alpha: 0.7), size: 18),
                    ],
                  ),
                ),
              )
            : SelectableText(
                _content!,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF1A1A2E), height: 1.5),
              ),
      ]),
    );
  }

  Widget _buildPortalUrlCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2D6A4F).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.link_rounded,
              color: Color(0xFF2D6A4F), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Portal URL',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 4),
            Text(_portalUrl!,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ]),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.open_in_new_rounded,
              color: Color(0xFF2D6A4F), size: 20),
          onPressed: () => _showOpenUrlSheet(_portalUrl!),
        ),
      ]),
    );
  }

  Widget _buildVisitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: () => _showOpenUrlSheet(_content!),
        icon: const Icon(Icons.open_in_new_rounded, size: 20),
        label: const Text('Visit Link',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2D6A4F),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildScanAgainButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.pushReplacementNamed(context, '/scanner'),
        icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
        label: const Text('Scan Again',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1A1A2E),
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  String _formatKey(String key) {
    return key.replaceAll('_', ' ').split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }
}
