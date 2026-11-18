import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/health_models.dart';

class AIAssistantView extends StatefulWidget {
  final UserVitals vitals;
  final DailyLog log;
  final String? initialQuery;

  const AIAssistantView({
    Key? key,
    required this.vitals,
    required this.log,
    this.initialQuery,
  }) : super(key: key);

  @override
  State<AIAssistantView> createState() => _AIAssistantViewState();
}

class _AIAssistantViewState extends State<AIAssistantView> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _messages.add({
      'isUser': false,
      'text': 'Hi there! I am your HealthX AI Coach. How can I help you reach your goals today?',
    });

    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage(widget.initialQuery!);
      });
    }
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    setState(() {
      _messages.add({'isUser': true, 'text': text});
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    // Brief AI "thinking" pause — just enough to feel natural
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;

    setState(() {
      _isTyping = false;
      _messages.add({
        'isUser': false,
        'text': _generateMockResponse(text),
      });
    });
    _scrollToBottom();
  }

  String _generateMockResponse(String query) {
    query = query.toLowerCase();
    final log = widget.log;
    final vitals = widget.vitals;
    final targetProtein = (vitals.targetCalories * 0.3) / 4;

    // ── INJURIES & REHAB ───────────────────────────────────────────────────
    if (query.contains('knee') && (query.contains('pain') || query.contains('injury') || query.contains('hurt'))) {
      return 'Knee pain is common. Avoid high-impact exercises like running or jumping. Instead, focus on low-impact activities like swimming or cycling. Strengthen your quads and hamstrings with static holds (wall sits) and glute bridges. If the pain is sharp, please rest and consult a physiotherapist!';
    } else if (query.contains('shoulder') && (query.contains('pain') || query.contains('injury') || query.contains('hurt'))) {
      return 'For shoulder discomfort, avoid overhead presses and heavy bench pressing. Focus on rotator cuff strengthening with light resistance bands (internal/external rotations) and improve your posture. Always warm up your shoulders dynamically before any upper body day.';
    } else if (query.contains('back') && (query.contains('pain') || query.contains('injury') || query.contains('hurt'))) {
      return 'Lower back pain often stems from tight hamstrings or a weak core. Stop heavy deadlifts and squats immediately. Instead, do the "McGill Big 3" (Bird-Dog, Side Plank, Curl-Up) for core stability, and gently stretch your hamstrings and hip flexors. If pain persists, see a doctor.';
    } else if (query.contains('injury') || query.contains('sprain') || query.contains('strain')) {
      return 'When dealing with an injury, remember the R.I.C.E protocol: Rest, Ice, Compression, and Elevation. Never push through sharp pain. Stick to training the uninjured parts of your body and prioritize protein and sleep to aid recovery.';
    }
    
    // ── DIETS & NUTRITION PROTOCOLS ────────────────────────────────────────
    else if (query.contains('keto') || query.contains('ketogenic')) {
      return 'The Keto diet focuses on high fat (70%), moderate protein (25%), and very low carbs (under 50g daily). It forces your body to burn fat for fuel. Good foods include avocados, nuts, eggs, fatty fish, and olive oil. Would you like me to adjust your macros for a keto protocol?';
    } else if (query.contains('vegan') || query.contains('plant based')) {
      return 'A vegan diet excludes all animal products. To hit your protein targets, you should focus on Lentils, Chickpeas, Tofu, Tempeh, Quinoa, and Plant-based protein powders (pea/rice blends). Ensure you supplement with Vitamin B12 and Omega-3s (flax/chia seeds).';
    } else if (query.contains('intermittent fasting') || query.contains('fasting')) {
      return 'Intermittent Fasting (like 16:8) restricts your eating window. It doesn\'t magically burn more fat than standard calorie restriction, but it helps control hunger and late-night snacking. Drink plenty of black coffee or green tea during your fasting window!';
    } else if (query.contains('bulking') || query.contains('muscle gain')) {
      return 'To build muscle (bulk), you need a caloric surplus (300-500 kcal above maintenance) and adequate protein (1.6 - 2.2g per kg of body weight). Focus on progressive overload in the gym and eat nutrient-dense foods like rice, oats, eggs, chicken, and nuts.';
    } else if (query.contains('cutting') || query.contains('fat loss')) {
      return 'For fat loss, you must be in a caloric deficit. Focus on high-volume, low-calorie foods (vegetables, lean meats) to stay full, keep your protein high to preserve muscle, and lift heavy weights. Cardio is just a tool to increase the deficit.';
    }
    
    // ── JUNK FOOD & ALTERNATIVES ───────────────────────────────────────────
    else if (query.contains('maggi') || query.contains('noodles')) {
      return 'Maggi is mostly refined flour and lacks protein and fiber. If you\'re craving it, try to make it healthier by adding a ton of veggies (peas, carrots, spinach) and cracking an egg into it or adding some paneer for protein!';
    } else if (query.contains('pizza') || query.contains('burger') || query.contains('junk')) {
      return 'It is completely fine to enjoy a pizza or burger occasionally (the 80/20 rule). One bad meal won\'t make you fat, just like one good meal won\'t make you fit. If you want a healthier alternative, try making a homemade burger with a lean chicken patty or a whole-wheat base pizza!';
    } else if (query.contains('sweet') || query.contains('sugar') || query.contains('chocolate')) {
      return 'Sugar cravings often indicate you aren\'t eating enough complex carbs or protein earlier in the day. Try swapping milk chocolate for 70%+ dark chocolate, or have some Greek yogurt with berries and a little honey.';
    }

    // ── SUPPLEMENTS ────────────────────────────────────────────────────────
    else if (query.contains('creatine')) {
      return 'Creatine Monohydrate is the most researched and safest supplement. It helps with explosive strength and muscle fullness by pulling water into the muscle cells. Take 3-5 grams daily consistently. No need to load or cycle it!';
    } else if (query.contains('whey') || query.contains('protein powder')) {
      return 'Whey protein is simply a convenient, high-quality food source derived from milk. It is perfectly safe. If you struggle to hit your ${targetProtein.toStringAsFixed(0)}g daily target from whole foods, 1-2 scoops a day is a great addition.';
    } else if (query.contains('pre workout') || query.contains('caffeine')) {
      return 'Pre-workouts mainly work because of their caffeine content. They are fine for occasional use, but don\'t rely on them daily or your body will build a tolerance. A strong cup of black coffee works just as well!';
    }

    // ── EXERCISE & WORKOUT ADVICE ──────────────────────────────────────────
    else if (query.contains('chest') || query.contains('push')) {
      return 'For a great chest workout, focus on the Barbell Bench Press (heavy, 4x6), Incline Dumbbell Press (for upper chest, 3x10), and Cable Crossovers (for a deep stretch and squeeze, 3x15).';
    } else if (query.contains('back') || query.contains('pull')) {
      return 'To build a wide and thick back, you need vertical and horizontal pulls. Include Pull-ups or Lat Pulldowns, Barbell or Dumbbell Rows, and Face Pulls for your rear delts.';
    } else if (query.contains('legs') || query.contains('squat')) {
      return 'Never skip leg day! A complete leg workout should include Barbell Squats (quads/glutes), Romanian Deadlifts (hamstrings), Leg Presses or Lunges, and Calf Raises.';
    } else if (query.contains('abs') || query.contains('belly fat')) {
      return 'You cannot spot-reduce belly fat with crunches. Abs are built in the gym but revealed in the kitchen! Focus on a caloric deficit to lose the fat, and do Planks and Leg Raises to build the core muscles.';
    }

    // ── LIVE DATA INTEGRATION (Macros, Sleep, etc.) ────────────────────────
    else if (query.contains('macros') || query.contains('protein') || query.contains('carbs') || query.contains('fat')) {
      if (log.meals.isEmpty) {
        return 'You haven\'t logged any meals today yet! Please log your meals so I can analyze your macros and give you accurate feedback.';
      }
      final remainingProtein = targetProtein - log.totalProtein;
      if (remainingProtein > 0) {
        return 'Looking at your data today, you\'ve consumed ${log.totalProtein.toStringAsFixed(0)}g of protein. You are slightly low on protein (${remainingProtein.toStringAsFixed(0)}g remaining). A high-protein dinner like Grilled Chicken Breast would help you hit your targets perfectly.';
      }
      return 'You are doing great! You\'ve hit your protein target of ${targetProtein.toStringAsFixed(0)}g for the day. Keep up the good work!';
    } else if (query.contains('dinner') || query.contains('eat') || query.contains('food')) {
      if (log.meals.isEmpty) {
         return 'I see you haven\'t logged any food today. To give you a personalized dinner recommendation, it helps if you track your breakfast and lunch. However, a safe high-protein bet is Grilled Salmon with Quinoa!';
      }
      return 'Based on what you\'ve eaten today, I recommend Grilled Salmon with Quinoa and Asparagus. It contains roughly 45g of protein, 35g of complex carbs, and heart-healthy omega-3s. Would you like the recipe?';
    } else if (query.contains('workout') || query.contains('hiit') || query.contains('exercise')) {
      return 'A 30-min HIIT session is a great idea! I suggest doing 4 rounds of: 45s Jumping Jacks, 45s Burpees, 45s Mountain Climbers, and 45s Plank, with 15s rest in between. I can log this for you if you complete it!';
    } else if (query.contains('tired') || query.contains('fatigue') || query.contains('sleep')) {
      final sleepHrs = log.sleepMinutes / 60;
      final waterLiters = log.waterMl / 1000;
      
      if (sleepHrs == 0 && waterLiters == 0) {
        return 'You haven\'t logged any sleep or water intake today! Dehydration and lack of sleep are the primary causes of fatigue. Please update your logs so I can give you a proper assessment.';
      } else if (sleepHrs < 6) {
        return 'I see you only logged ${sleepHrs.toStringAsFixed(1)} hours of sleep last night, and your water intake is at ${waterLiters.toStringAsFixed(1)}L. Lack of sleep is definitely causing your fatigue. Try to aim for at least 7-8 hours tonight.';
      } else if (waterLiters < 2.0) {
        return 'You got a good ${sleepHrs.toStringAsFixed(1)} hours of sleep, but you\'ve only drank ${waterLiters.toStringAsFixed(1)}L of water! Dehydration is likely causing your tiredness. Go drink 500ml of water right now!';
      }
      return 'Your sleep and water intake look great today! Sometimes fatigue can be caused by stress or overtraining. Consider taking an active recovery day or doing some light yoga.';
    }
    
    // ── FALLBACK ───────────────────────────────────────────────────────────
    return 'That is a great question! I am equipped to help you with workout plans, diet (keto, vegan, bulking), injury advice (knee, back, shoulder), supplements (creatine, whey), and analyzing your daily logs. What would you like to focus on today?';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.luxeGold, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppTheme.luxeGold, size: 22),
            SizedBox(width: 8),
            Text('AI Coach', style: TextStyle(color: AppTheme.textDarkPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.borderDark, height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                final msg = _messages[index];
                return _buildChatBubble(msg['text'], msg['isUser']);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.luxeGold : AppTheme.surfaceDark,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
          ),
          border: isUser ? null : Border.all(color: AppTheme.borderDark),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.black : AppTheme.textDarkPrimary,
            fontSize: 14,
            height: 1.4,
            fontWeight: isUser ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: AppTheme.borderDark),
        ),
        child: const Text('AI is thinking...', style: TextStyle(color: AppTheme.textDarkSecondary, fontSize: 13, fontStyle: FontStyle.italic)),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(top: BorderSide(color: AppTheme.borderDark)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.bgDark,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: AppTheme.textDarkPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Ask me anything...',
                    hintStyle: TextStyle(color: AppTheme.textDarkMuted, fontSize: 14),
                    border: InputBorder.none,
                  ),
                  onSubmitted: _sendMessage,
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => _sendMessage(_controller.text),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppTheme.luxeGold,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.black, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
