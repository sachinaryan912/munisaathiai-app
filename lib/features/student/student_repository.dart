import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class StudentRepository {
  final _dio = ApiClient.instance.dio;

  Future<Map<String, dynamic>> getDashboard() => apiCall(() async {
        final res = await _dio.get('/student/dashboard');
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> getProgress() => apiCall(() async {
        final res = await _dio.get('/student/progress');
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> getBuddy() => apiCall(() async {
        final res = await _dio.get('/student/buddy');
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> logBuddySession({required String topic, int duration = 30, bool helped = true, String? peerReflection, int? buddyRating}) =>
      apiCall(() async {
        final res = await _dio.post('/student/buddy/session', data: {
          'topic': topic,
          'duration': duration,
          'helped': helped,
          'peerReflection': ?peerReflection,
          'buddyRating': ?buddyRating,
        });
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> toggleActivity(int id) => apiCall(() async {
        final res = await _dio.post('/student/buddy/activity/toggle/$id');
        return res.data as Map<String, dynamic>;
      });

  Future<List<Map<String, dynamic>>> getStudyModules() => apiCall(() async {
        final res = await _dio.get('/student/study');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<Map<String, dynamic>> addStudyChapter({required String subject, required String topic}) => apiCall(() async {
        final res = await _dio.post('/student/study', data: {'subject': subject, 'topic': topic});
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> updateStudyReflection({
    required int moduleId,
    required String understand,
    required String problem,
    required String learning,
    required String communicate,
  }) =>
      apiCall(() async {
        final res = await _dio.put('/student/study/$moduleId', data: {
          'understand': understand,
          'problem': problem,
          'learning': learning,
          'communicate': communicate,
        });
        return res.data as Map<String, dynamic>;
      });

  Future<List<Map<String, dynamic>>> getPeerTeaching() => apiCall(() async {
        final res = await _dio.get('/student/peer-teaching');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<Map<String, dynamic>> logPeerTeaching({required String topic, int studentCount = 1, String? reflection}) => apiCall(() async {
        final res = await _dio.post('/student/peer-teaching', data: {
          'topic': topic,
          'studentCount': studentCount,
          'reflection': ?reflection,
        });
        return res.data as Map<String, dynamic>;
      });

  Future<List<Map<String, dynamic>>> getFeedback() => apiCall(() async {
        final res = await _dio.get('/student/feedback');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<Map<String, dynamic>> submitFeedback({String category = 'general', required String content, int rating = 5}) => apiCall(() async {
        final res = await _dio.post('/student/feedback', data: {'category': category, 'content': content, 'rating': rating});
        return res.data as Map<String, dynamic>;
      });

  Future<List<Map<String, dynamic>>> getAssignments() => apiCall(() async {
        final res = await _dio.get('/student/assignments');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<Map<String, dynamic>> submitAssignment({required File file, required String subject, String title = 'Untitled Assignment'}) => apiCall(() async {
        final form = FormData.fromMap({
          'subject': subject,
          'title': title,
          'file': await MultipartFile.fromFile(file.path, filename: file.path.split(Platform.pathSeparator).last),
        });
        final res = await _dio.post('/student/assignments', data: form);
        return res.data as Map<String, dynamic>;
      });

  Future<List<int>> getAssignmentFile(int id) => apiCall(() async {
        final res = await _dio.get<List<int>>('/student/assignments/$id/file', options: Options(responseType: ResponseType.bytes));
        return res.data!;
      });

  Future<List<Map<String, dynamic>>> getProgressChart() => apiCall(() async {
        final res = await _dio.get('/student/progress-chart');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<Map<String, dynamic>> logProgressChart({required String topic, required int previousTime, required int currentTime}) => apiCall(() async {
        final res = await _dio.post('/student/progress-chart', data: {'topic': topic, 'previousTime': previousTime, 'currentTime': currentTime});
        return res.data as Map<String, dynamic>;
      });

  // ── Socially Strong ────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getSocialVoiceLogs() => apiCall(() async {
        final res = await _dio.get('/student/social-voice');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<void> logSocialVoice({required String issue, String? actionTaken}) => apiCall(() async {
        await _dio.post('/student/social-voice', data: {'issue': issue, 'actionTaken': ?actionTaken});
      });

  // ── Eklavya System ─────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getEklavyaSubmissions() => apiCall(() async {
        final res = await _dio.get('/student/eklavya');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<void> submitEklavya({required String topic, required String content}) => apiCall(() async {
        await _dio.post('/student/eklavya', data: {'topic': topic, 'content': content});
      });

  // ── Mai Shikshit Hokar ─────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getLifeApplicationLogs() => apiCall(() async {
        final res = await _dio.get('/student/life-application');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<void> logLifeApplication({required String topic, String? healthNote, String? prosperityNote, String? relationNote, String? participationNote}) =>
      apiCall(() async {
        await _dio.post('/student/life-application', data: {
          'topic': topic,
          'healthNote': ?healthNote,
          'prosperityNote': ?prosperityNote,
          'relationNote': ?relationNote,
          'participationNote': ?participationNote,
        });
      });

  // ── Jeevan ko Samjhne ka Kaushal ───────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getFortnightlySelfEvals() => apiCall(() async {
        final res = await _dio.get('/student/fortnightly-self-eval');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<void> submitFortnightlySelfEval(List<String> answers) => apiCall(() async {
        await _dio.post('/student/fortnightly-self-eval', data: {'answersJson': jsonEncode(answers)});
      });

  // ── Answer Pattern ─────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getAnswerPatterns() => apiCall(() async {
        final res = await _dio.get('/student/answer-pattern');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<void> submitAnswerPattern({
    required String chapter,
    required String question,
    String? points,
    String? accurateAnswer,
  }) =>
      apiCall(() async {
        await _dio.post('/student/answer-pattern', data: {
          'chapter': chapter,
          'question': question,
          'points': ?points,
          'accurateAnswer': ?accurateAnswer,
        });
      });

  // ── Exam Evaluation ────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getExamSelfDiagnostics() => apiCall(() async {
        final res = await _dio.get('/student/exam-self-diagnostic');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<void> submitExamSelfDiagnostic({required String examName, required Map<String, dynamic> diagnosis}) => apiCall(() async {
        await _dio.post('/student/exam-self-diagnostic', data: {'examName': examName, 'diagnosisJson': jsonEncode(diagnosis)});
      });

  // ── Reasoning / Brain Mapping / About ──────────────────────────────────────
  Future<List<Map<String, dynamic>>> getSkillPracticeLogs() => apiCall(() async {
        final res = await _dio.get('/student/skill-practice');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<void> logSkillPractice({required String skillType, required String topic, String? notes, int? correctCount, int? totalCount}) => apiCall(() async {
        await _dio.post('/student/skill-practice', data: {
          'skillType': skillType,
          'topic': topic,
          'notes': ?notes,
          'correctCount': ?correctCount,
          'totalCount': ?totalCount,
        });
      });

  // ── Learning Style Quiz ────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getLearningStyleResults() => apiCall(() async {
        final res = await _dio.get('/student/learning-style');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<Map<String, dynamic>> submitLearningStyleQuiz({required int kinesthetic, required int audio, required int video, required int linguistic, required int musical}) =>
      apiCall(() async {
        final res = await _dio.post('/student/learning-style', data: {
          'kinesthetic': kinesthetic,
          'audio': audio,
          'video': video,
          'linguistic': linguistic,
          'musical': musical,
        });
        return res.data as Map<String, dynamic>;
      });

  // ── IPDS Career Assessment ─────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getCareerAssessments() => apiCall(() async {
        final res = await _dio.get('/student/career-assessment');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<Map<String, dynamic>> submitCareerAssessment({required String interests, required String strengths, String? wishlist, String? familyBackground}) =>
      apiCall(() async {
        final res = await _dio.post('/student/career-assessment', data: {
          'interests': interests,
          'strengths': strengths,
          'wishlist': ?wishlist,
          'familyBackground': ?familyBackground,
        });
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> getMyParliamentRole() => apiCall(() async {
        final res = await _dio.get('/student/parliament/my-role');
        return res.data as Map<String, dynamic>;
      });
}
