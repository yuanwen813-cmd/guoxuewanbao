class AskQuestionTemplate {
  const AskQuestionTemplate({
    required this.id,
    required this.scenarioId,
    required this.text,
    required this.sortOrder,
    this.enabled = true,
  });

  final String id;
  final String scenarioId;
  final String text;
  final int sortOrder;
  final bool enabled;
}

class AskScenario {
  const AskScenario({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.templates,
    this.description,
    this.enabled = true,
  });

  final String id;
  final String name;
  final String? description;
  final int sortOrder;
  final bool enabled;
  final List<AskQuestionTemplate> templates;
}

class AskQuestionTemplateLibrary {
  AskQuestionTemplateLibrary._();

  static const scenarios = <AskScenario>[
    AskScenario(
      id: 'relationship',
      name: '感情',
      sortOrder: 10,
      templates: [
        AskQuestionTemplate(
            id: 'relationship_contact_001',
            scenarioId: 'relationship',
            text: '我现在适合主动联系对方吗？',
            sortOrder: 10),
        AskQuestionTemplate(
            id: 'relationship_future_001',
            scenarioId: 'relationship',
            text: '这段关系还有继续发展的机会吗？',
            sortOrder: 20),
        AskQuestionTemplate(
            id: 'relationship_confession_001',
            scenarioId: 'relationship',
            text: '我现在适合向对方表达心意吗？',
            sortOrder: 30),
        AskQuestionTemplate(
            id: 'relationship_development_001',
            scenarioId: 'relationship',
            text: '我和对方目前的关系会继续发展吗？',
            sortOrder: 40),
        AskQuestionTemplate(
            id: 'relationship_wait_001',
            scenarioId: 'relationship',
            text: '我应该继续等待这段关系，还是往前走？',
            sortOrder: 50),
        AskQuestionTemplate(
            id: 'relationship_distance_001',
            scenarioId: 'relationship',
            text: '最近这段感情关系中，我更应该主动还是保持距离？',
            sortOrder: 60),
        AskQuestionTemplate(
            id: 'relationship_obstacle_001',
            scenarioId: 'relationship',
            text: '我和对方之间当前最大的阻碍是什么？',
            sortOrder: 70),
        AskQuestionTemplate(
            id: 'relationship_investment_001',
            scenarioId: 'relationship',
            text: '目前这段关系值得我继续投入吗？',
            sortOrder: 80),
      ],
    ),
    AskScenario(
      id: 'work',
      name: '工作',
      sortOrder: 20,
      templates: [
        AskQuestionTemplate(
            id: 'work_change_001',
            scenarioId: 'work',
            text: '我现在适合换工作吗？',
            sortOrder: 10),
        AskQuestionTemplate(
            id: 'work_stay_001',
            scenarioId: 'work',
            text: '目前这份工作值得继续坚持吗？',
            sortOrder: 20),
        AskQuestionTemplate(
            id: 'work_opportunity_001',
            scenarioId: 'work',
            text: '最近出现的这个工作机会值得接受吗？',
            sortOrder: 30),
        AskQuestionTemplate(
            id: 'work_improve_001',
            scenarioId: 'work',
            text: '我近期的工作局面会不会出现改善？',
            sortOrder: 40),
        AskQuestionTemplate(
            id: 'work_compete_001',
            scenarioId: 'work',
            text: '这次竞聘对我来说是否值得争取？',
            sortOrder: 50),
        AskQuestionTemplate(
            id: 'work_change_or_stable_001',
            scenarioId: 'work',
            text: '我现在更适合主动求变，还是暂时稳定下来？',
            sortOrder: 60),
        AskQuestionTemplate(
            id: 'work_difficulty_001',
            scenarioId: 'work',
            text: '目前工作中的这个困难能否顺利解决？',
            sortOrder: 70),
        AskQuestionTemplate(
            id: 'work_direction_001',
            scenarioId: 'work',
            text: '我应该继续留在现在的岗位，还是考虑新的方向？',
            sortOrder: 80),
      ],
    ),
    AskScenario(
      id: 'wealth',
      name: '财运',
      sortOrder: 30,
      templates: [
        AskQuestionTemplate(
            id: 'wealth_improve_001',
            scenarioId: 'wealth',
            text: '我近期的财务状况有没有改善的机会？',
            sortOrder: 10),
        AskQuestionTemplate(
            id: 'wealth_investment_001',
            scenarioId: 'wealth',
            text: '现在适合扩大投入，还是应该更加保守？',
            sortOrder: 20),
        AskQuestionTemplate(
            id: 'wealth_expense_001',
            scenarioId: 'wealth',
            text: '这笔支出现在是否值得？',
            sortOrder: 30),
        AskQuestionTemplate(
            id: 'wealth_opportunity_001',
            scenarioId: 'wealth',
            text: '最近这个赚钱机会值得我继续投入精力吗？',
            sortOrder: 40),
        AskQuestionTemplate(
            id: 'wealth_open_or_save_001',
            scenarioId: 'wealth',
            text: '我现在更应该开源，还是先控制支出？',
            sortOrder: 50),
        AskQuestionTemplate(
            id: 'wealth_pressure_001',
            scenarioId: 'wealth',
            text: '近期我的财务压力有没有缓解的趋势？',
            sortOrder: 60),
        AskQuestionTemplate(
            id: 'wealth_side_job_001',
            scenarioId: 'wealth',
            text: '这个副业方向值得我继续尝试吗？',
            sortOrder: 70),
        AskQuestionTemplate(
            id: 'wealth_plan_001',
            scenarioId: 'wealth',
            text: '我现在做的这个赚钱计划是否值得继续推进？',
            sortOrder: 80),
      ],
    ),
    AskScenario(
      id: 'cooperation',
      name: '合作',
      sortOrder: 40,
      templates: [
        AskQuestionTemplate(
            id: 'cooperation_continue_001',
            scenarioId: 'cooperation',
            text: '这次合作值得继续推进吗？',
            sortOrder: 10),
        AskQuestionTemplate(
            id: 'cooperation_partner_001',
            scenarioId: 'cooperation',
            text: '对方是否适合作为长期合作伙伴？',
            sortOrder: 20),
        AskQuestionTemplate(
            id: 'cooperation_risk_001',
            scenarioId: 'cooperation',
            text: '这次合作目前最大的风险在哪里？',
            sortOrder: 30),
        AskQuestionTemplate(
            id: 'cooperation_push_001',
            scenarioId: 'cooperation',
            text: '我现在适合主动推动这次合作吗？',
            sortOrder: 40),
        AskQuestionTemplate(
            id: 'cooperation_timing_001',
            scenarioId: 'cooperation',
            text: '这次合作更适合快速推进，还是继续观察？',
            sortOrder: 50),
        AskQuestionTemplate(
            id: 'cooperation_adjust_001',
            scenarioId: 'cooperation',
            text: '当前这个合作方案是否需要调整？',
            sortOrder: 60),
        AskQuestionTemplate(
            id: 'cooperation_coordination_001',
            scenarioId: 'cooperation',
            text: '我和对方在这次合作中能否顺利磨合？',
            sortOrder: 70),
        AskQuestionTemplate(
            id: 'cooperation_resource_001',
            scenarioId: 'cooperation',
            text: '这次合作值得我投入更多时间和资源吗？',
            sortOrder: 80),
      ],
    ),
    AskScenario(
      id: 'interpersonal',
      name: '人际',
      sortOrder: 50,
      templates: [
        AskQuestionTemplate(
            id: 'interpersonal_improve_001',
            scenarioId: 'interpersonal',
            text: '我应该主动改善和这个人的关系吗？',
            sortOrder: 10),
        AskQuestionTemplate(
            id: 'interpersonal_conflict_001',
            scenarioId: 'interpersonal',
            text: '目前这段关系中的矛盾能否缓和？',
            sortOrder: 20),
        AskQuestionTemplate(
            id: 'interpersonal_contact_001',
            scenarioId: 'interpersonal',
            text: '我现在更适合主动沟通，还是保持距离？',
            sortOrder: 30),
        AskQuestionTemplate(
            id: 'interpersonal_explain_001',
            scenarioId: 'interpersonal',
            text: '这次误会是否适合主动解释？',
            sortOrder: 40),
        AskQuestionTemplate(
            id: 'interpersonal_maintain_001',
            scenarioId: 'interpersonal',
            text: '我和这个人的关系值得继续维护吗？',
            sortOrder: 50),
        AskQuestionTemplate(
            id: 'interpersonal_attention_001',
            scenarioId: 'interpersonal',
            text: '目前这段人际关系中，我应该注意什么？',
            sortOrder: 60),
        AskQuestionTemplate(
            id: 'interpersonal_reach_out_001',
            scenarioId: 'interpersonal',
            text: '我现在是否适合主动联系这个人？',
            sortOrder: 70),
        AskQuestionTemplate(
            id: 'interpersonal_space_001',
            scenarioId: 'interpersonal',
            text: '这段关系未来还有改善的空间吗？',
            sortOrder: 80),
      ],
    ),
    AskScenario(
      id: 'study',
      name: '学业',
      sortOrder: 60,
      templates: [
        AskQuestionTemplate(
            id: 'study_direction_001',
            scenarioId: 'study',
            text: '我目前的学习方向是否适合继续坚持？',
            sortOrder: 10),
        AskQuestionTemplate(
            id: 'study_exam_001',
            scenarioId: 'study',
            text: '这次考试我现在最应该注意什么？',
            sortOrder: 20),
        AskQuestionTemplate(
            id: 'study_method_001',
            scenarioId: 'study',
            text: '我是否应该调整现在的学习方法？',
            sortOrder: 30),
        AskQuestionTemplate(
            id: 'study_major_001',
            scenarioId: 'study',
            text: '目前这个专业方向适合我继续深入吗？',
            sortOrder: 40),
        AskQuestionTemplate(
            id: 'study_foundation_001',
            scenarioId: 'study',
            text: '我现在更应该补基础，还是继续往前学？',
            sortOrder: 50),
        AskQuestionTemplate(
            id: 'study_state_001',
            scenarioId: 'study',
            text: '最近的学习状态有没有改善的机会？',
            sortOrder: 60),
        AskQuestionTemplate(
            id: 'study_selection_001',
            scenarioId: 'study',
            text: '我是否应该参加这次考试或选拔？',
            sortOrder: 70),
        AskQuestionTemplate(
            id: 'study_plan_001',
            scenarioId: 'study',
            text: '目前这个学习计划值得继续执行吗？',
            sortOrder: 80),
      ],
    ),
    AskScenario(
      id: 'travel',
      name: '出行',
      sortOrder: 70,
      templates: [
        AskQuestionTemplate(
            id: 'travel_plan_001',
            scenarioId: 'travel',
            text: '这次出行现在是否适合按计划进行？',
            sortOrder: 10),
        AskQuestionTemplate(
            id: 'travel_arrangement_001',
            scenarioId: 'travel',
            text: '这趟旅程是否需要调整时间或安排？',
            sortOrder: 20),
        AskQuestionTemplate(
            id: 'travel_destination_001',
            scenarioId: 'travel',
            text: '我现在是否适合前往这个地方？',
            sortOrder: 30),
        AskQuestionTemplate(
            id: 'travel_attention_001',
            scenarioId: 'travel',
            text: '这次出行我最应该注意什么？',
            sortOrder: 40),
        AskQuestionTemplate(
            id: 'travel_rush_001',
            scenarioId: 'travel',
            text: '这个行程安排是否过于仓促？',
            sortOrder: 50),
        AskQuestionTemplate(
            id: 'travel_delay_001',
            scenarioId: 'travel',
            text: '我是否应该推迟这次出行？',
            sortOrder: 60),
        AskQuestionTemplate(
            id: 'travel_adjust_001',
            scenarioId: 'travel',
            text: '这次出行更适合按原计划，还是做一些调整？',
            sortOrder: 70),
        AskQuestionTemplate(
            id: 'travel_decision_001',
            scenarioId: 'travel',
            text: '目前这个出行决定是否值得继续执行？',
            sortOrder: 80),
      ],
    ),
    AskScenario(
      id: 'choice',
      name: '选择',
      sortOrder: 80,
      templates: [
        AskQuestionTemplate(
            id: 'choice_change_001',
            scenarioId: 'choice',
            text: '面对现在这两个选择，我更适合主动改变还是维持现状？',
            sortOrder: 10),
        AskQuestionTemplate(
            id: 'choice_continue_001',
            scenarioId: 'choice',
            text: '这件事现在值得我继续推进吗？',
            sortOrder: 20),
        AskQuestionTemplate(
            id: 'choice_action_001',
            scenarioId: 'choice',
            text: '我应该现在行动，还是再观察一段时间？',
            sortOrder: 30),
        AskQuestionTemplate(
            id: 'choice_timing_001',
            scenarioId: 'choice',
            text: '这个决定现在做是否合适？',
            sortOrder: 40),
        AskQuestionTemplate(
            id: 'choice_direction_001',
            scenarioId: 'choice',
            text: '目前这个方向值得继续坚持吗？',
            sortOrder: 50),
        AskQuestionTemplate(
            id: 'choice_abandon_001',
            scenarioId: 'choice',
            text: '我是否应该放弃现在这个计划？',
            sortOrder: 60),
        AskQuestionTemplate(
            id: 'choice_active_001',
            scenarioId: 'choice',
            text: '当前局面下，我更适合主动还是保守？',
            sortOrder: 70),
        AskQuestionTemplate(
            id: 'choice_opportunity_001',
            scenarioId: 'choice',
            text: '这个机会值得我抓住吗？',
            sortOrder: 80),
      ],
    ),
  ];

  static List<AskScenario> enabledScenarios([List<AskScenario>? source]) {
    final configured = source ?? scenarios;
    return configured
        .where((scenario) => scenario.enabled)
        .map(
          (scenario) => AskScenario(
            id: scenario.id,
            name: scenario.name,
            description: scenario.description,
            sortOrder: scenario.sortOrder,
            templates: scenario.templates
                .where((template) => template.enabled)
                .toList()
              ..sort(
                  (left, right) => left.sortOrder.compareTo(right.sortOrder)),
          ),
        )
        .where((scenario) => scenario.templates.isNotEmpty)
        .toList()
      ..sort((left, right) => left.sortOrder.compareTo(right.sortOrder));
  }

  static List<String> validate([List<AskScenario>? source]) {
    final issues = <String>[];
    final scenarioIds = <String>{};
    final templateIds = <String>{};
    for (final scenario in source ?? scenarios) {
      if (scenario.id.trim().isEmpty || scenario.name.trim().isEmpty) {
        issues.add('场景标识或名称为空');
      }
      if (!scenarioIds.add(scenario.id)) issues.add('场景标识重复：${scenario.id}');
      for (final template in scenario.templates) {
        if (template.id.trim().isEmpty || template.text.trim().isEmpty) {
          issues.add('问题模板标识或内容为空');
        }
        if (template.scenarioId != scenario.id) {
          issues.add('问题模板场景不匹配：${template.id}');
        }
        if (!templateIds.add(template.id)) {
          issues.add('问题模板标识重复：${template.id}');
        }
      }
    }
    return issues;
  }
}
