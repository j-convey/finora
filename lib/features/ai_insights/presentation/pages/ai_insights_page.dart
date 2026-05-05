import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _Message {
  _Message({required this.text, required this.isUser})
      : timestamp = DateTime.now();
  final String text;
  final bool isUser;
  final DateTime timestamp;
}

final _chatProvider =
    StateNotifierProvider.autoDispose<_ChatNotifier, List<_Message>>(
  (ref) => _ChatNotifier(),
);

class _ChatNotifier extends StateNotifier<List<_Message>> {
  _ChatNotifier() : super([]) {
    _addBot(
      "Hi! I'm your Finora AI assistant 👋\n\n"
      "I can analyze your spending, predict future expenses, and help you reach your goals. "
      "Try asking me:\n• \"How am I spending this month?\"\n• \"What's my savings rate?\"\n• \"Predict next month\"",
    );
  }

  void _addBot(String text) {
    state = [...state, _Message(text: text, isUser: false)];
  }

  void send(String text) {
    if (text.trim().isEmpty) return;
    state = [...state, _Message(text: text.trim(), isUser: true)];
    Future.delayed(const Duration(milliseconds: 900), () {
      _addBot(_respond(text.toLowerCase()));
    });
  }

  String _respond(String input) {
    if (input.contains('spend') || input.contains('expense')) {
      return "Based on your transactions this month:\n\n"
          "• Rent: \$1,800 (77.8%)\n"
          "• Groceries: \$141.63 (6.1%)\n"
          "• Utilities: \$92.30 (4.0%)\n"
          "• Health: \$80.00 (3.5%)\n"
          "• Shopping: \$67.99 (2.9%)\n\n"
          "Total: \$2,315.93 — you're tracking 8% below last month. Great job!";
    }
    if (input.contains('budget')) {
      return "Your budget health is strong! 6 of 7 categories are on track.\n\n"
          "⚠️ Health is at 80% with 10 days left — watch this one.\n\n"
          "Groceries and Dining have the most headroom. Would you like me to suggest a reallocation?";
    }
    if (input.contains('sav')) {
      return "You're saving ~40% of your income this month — excellent!\n\n"
          "• Emergency fund: 6.8 months covered ✓\n"
          "• Monthly surplus: ~\$3,234\n\n"
          "I'd suggest directing \$300–500/month to your investment portfolio to accelerate compound growth.";
    }
    if (input.contains('predict') ||
        input.contains('forecast') ||
        input.contains('next month')) {
      return "Next month forecast based on your patterns:\n\n"
          "📈 Expected income: \$5,200 – \$6,050\n"
          "📉 Expected expenses: \$2,200 – \$2,500\n"
          "💰 Projected savings: \$2,700 – \$3,850\n\n"
          "Fixed costs (rent + subscriptions) will be ~\$1,826. Looks solid!";
    }
    if (input.contains('invest') || input.contains('portfolio')) {
      return "Your investment portfolio sits at \$28,350 — up ~12.3% YTD.\n\n"
          "Given your savings rate, increasing your monthly contribution by \$200–300 would have minimal lifestyle impact and accelerate your timeline significantly.";
    }
    if (input.contains('categor')) {
      return "A few transactions could use a second look:\n\n"
          "• \"Amazon Order\" → currently tagged as Shopping\n"
          "• \"Uber Ride\" → Transport ✓\n"
          "• \"Doctor Copay\" → Health ✓\n\n"
          "Everything else looks well categorized. Want me to auto-categorize future transactions?";
    }
    if (input.contains('net worth')) {
      return "Your current net worth is \$44,671.17.\n\n"
          "📊 Assets: \$45,918.67\n"
          "💳 Liabilities: \$1,247.50\n\n"
          "Your net worth has grown ~8.2% in the last 90 days. Keep it up!";
    }
    return "Great question! Based on your data, here's a quick snapshot:\n\n"
        "• Net worth: \$44,671 (+8.2% this quarter)\n"
        "• Savings rate: ~40% this month\n"
        "• Budgets: 6/7 categories on track\n\n"
        "Try asking about spending, budgets, savings rate, or next month's forecast!";
  }
}

// ── Page ────────────────────────────────────────────────────────────────────

class AiInsightsPage extends ConsumerStatefulWidget {
  const AiInsightsPage({super.key});

  @override
  ConsumerState<AiInsightsPage> createState() => _AiInsightsPageState();
}

class _AiInsightsPageState extends ConsumerState<AiInsightsPage> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _ctrl.text;
    ref.read(_chatProvider.notifier).send(text);
    _ctrl.clear();
    Future.delayed(
      const Duration(milliseconds: 950),
      () {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(_chatProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: cs.primary, size: 20),
            const SizedBox(width: 8),
            const Text('AI Insights'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Clear chat',
            onPressed: () =>
                ref.invalidate(_chatProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Suggestion chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                'How am I spending?',
                'Savings rate?',
                'Predict next month',
                'Net worth',
                'Budget check',
              ]
                  .map(
                    (q) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(q),
                        onPressed: () {
                          _ctrl.text = q;
                          _send();
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: messages.length,
              itemBuilder: (context, i) =>
                  _Bubble(message: messages[i]),
            ),
          ),
          // Input row
          Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              bottom: MediaQuery.viewInsetsOf(context).bottom + 12,
              top: 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: InputDecoration(
                      hintText: 'Ask about your finances…',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _send(),
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.send_rounded),
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final _Message message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        margin: const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? cs.primary : cs.surfaceContainerHigh,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          message.text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isUser ? cs.onPrimary : cs.onSurface,
              ),
        ),
      ),
    );
  }
}
