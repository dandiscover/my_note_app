// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $NotesTable extends Notes with TableInfo<$NotesTable, Note> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('raw'),
  );
  static const VerificationMeta _editorModeMeta = const VerificationMeta(
    'editorMode',
  );
  @override
  late final GeneratedColumn<String> editorMode = GeneratedColumn<String>(
    'editor_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('plain'),
  );
  static const VerificationMeta _isLockedMeta = const VerificationMeta(
    'isLocked',
  );
  @override
  late final GeneratedColumn<int> isLocked = GeneratedColumn<int>(
    'is_locked',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _inquiryQuestionMeta = const VerificationMeta(
    'inquiryQuestion',
  );
  @override
  late final GeneratedColumn<String> inquiryQuestion = GeneratedColumn<String>(
    'inquiry_question',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inquiryConclusionMeta = const VerificationMeta(
    'inquiryConclusion',
  );
  @override
  late final GeneratedColumn<String> inquiryConclusion =
      GeneratedColumn<String>(
        'inquiry_conclusion',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _exploreTasksMeta = const VerificationMeta(
    'exploreTasks',
  );
  @override
  late final GeneratedColumn<String> exploreTasks = GeneratedColumn<String>(
    'explore_tasks',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _contentFormatMeta = const VerificationMeta(
    'contentFormat',
  );
  @override
  late final GeneratedColumn<String> contentFormat = GeneratedColumn<String>(
    'content_format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('markdown'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    content,
    updatedAt,
    status,
    editorMode,
    isLocked,
    tags,
    inquiryQuestion,
    inquiryConclusion,
    exploreTasks,
    contentFormat,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Note> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('editor_mode')) {
      context.handle(
        _editorModeMeta,
        editorMode.isAcceptableOrUnknown(data['editor_mode']!, _editorModeMeta),
      );
    }
    if (data.containsKey('is_locked')) {
      context.handle(
        _isLockedMeta,
        isLocked.isAcceptableOrUnknown(data['is_locked']!, _isLockedMeta),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('inquiry_question')) {
      context.handle(
        _inquiryQuestionMeta,
        inquiryQuestion.isAcceptableOrUnknown(
          data['inquiry_question']!,
          _inquiryQuestionMeta,
        ),
      );
    }
    if (data.containsKey('inquiry_conclusion')) {
      context.handle(
        _inquiryConclusionMeta,
        inquiryConclusion.isAcceptableOrUnknown(
          data['inquiry_conclusion']!,
          _inquiryConclusionMeta,
        ),
      );
    }
    if (data.containsKey('explore_tasks')) {
      context.handle(
        _exploreTasksMeta,
        exploreTasks.isAcceptableOrUnknown(
          data['explore_tasks']!,
          _exploreTasksMeta,
        ),
      );
    }
    if (data.containsKey('content_format')) {
      context.handle(
        _contentFormatMeta,
        contentFormat.isAcceptableOrUnknown(
          data['content_format']!,
          _contentFormatMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Note map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Note(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      editorMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}editor_mode'],
      )!,
      isLocked: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_locked'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      inquiryQuestion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inquiry_question'],
      ),
      inquiryConclusion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inquiry_conclusion'],
      ),
      exploreTasks: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}explore_tasks'],
      )!,
      contentFormat: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_format'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }
}

class Note extends DataClass implements Insertable<Note> {
  final String id;
  final String title;
  final String content;
  final String? updatedAt;
  final String status;
  final String editorMode;
  final int isLocked;
  final String tags;
  final String? inquiryQuestion;
  final String? inquiryConclusion;
  final String exploreTasks;
  final String contentFormat;
  final String? createdAt;
  const Note({
    required this.id,
    required this.title,
    required this.content,
    this.updatedAt,
    required this.status,
    required this.editorMode,
    required this.isLocked,
    required this.tags,
    this.inquiryQuestion,
    this.inquiryConclusion,
    required this.exploreTasks,
    required this.contentFormat,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    map['status'] = Variable<String>(status);
    map['editor_mode'] = Variable<String>(editorMode);
    map['is_locked'] = Variable<int>(isLocked);
    map['tags'] = Variable<String>(tags);
    if (!nullToAbsent || inquiryQuestion != null) {
      map['inquiry_question'] = Variable<String>(inquiryQuestion);
    }
    if (!nullToAbsent || inquiryConclusion != null) {
      map['inquiry_conclusion'] = Variable<String>(inquiryConclusion);
    }
    map['explore_tasks'] = Variable<String>(exploreTasks);
    map['content_format'] = Variable<String>(contentFormat);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      id: Value(id),
      title: Value(title),
      content: Value(content),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      status: Value(status),
      editorMode: Value(editorMode),
      isLocked: Value(isLocked),
      tags: Value(tags),
      inquiryQuestion: inquiryQuestion == null && nullToAbsent
          ? const Value.absent()
          : Value(inquiryQuestion),
      inquiryConclusion: inquiryConclusion == null && nullToAbsent
          ? const Value.absent()
          : Value(inquiryConclusion),
      exploreTasks: Value(exploreTasks),
      contentFormat: Value(contentFormat),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory Note.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Note(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
      status: serializer.fromJson<String>(json['status']),
      editorMode: serializer.fromJson<String>(json['editorMode']),
      isLocked: serializer.fromJson<int>(json['isLocked']),
      tags: serializer.fromJson<String>(json['tags']),
      inquiryQuestion: serializer.fromJson<String?>(json['inquiryQuestion']),
      inquiryConclusion: serializer.fromJson<String?>(
        json['inquiryConclusion'],
      ),
      exploreTasks: serializer.fromJson<String>(json['exploreTasks']),
      contentFormat: serializer.fromJson<String>(json['contentFormat']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String>(content),
      'updatedAt': serializer.toJson<String?>(updatedAt),
      'status': serializer.toJson<String>(status),
      'editorMode': serializer.toJson<String>(editorMode),
      'isLocked': serializer.toJson<int>(isLocked),
      'tags': serializer.toJson<String>(tags),
      'inquiryQuestion': serializer.toJson<String?>(inquiryQuestion),
      'inquiryConclusion': serializer.toJson<String?>(inquiryConclusion),
      'exploreTasks': serializer.toJson<String>(exploreTasks),
      'contentFormat': serializer.toJson<String>(contentFormat),
      'createdAt': serializer.toJson<String?>(createdAt),
    };
  }

  Note copyWith({
    String? id,
    String? title,
    String? content,
    Value<String?> updatedAt = const Value.absent(),
    String? status,
    String? editorMode,
    int? isLocked,
    String? tags,
    Value<String?> inquiryQuestion = const Value.absent(),
    Value<String?> inquiryConclusion = const Value.absent(),
    String? exploreTasks,
    String? contentFormat,
    Value<String?> createdAt = const Value.absent(),
  }) => Note(
    id: id ?? this.id,
    title: title ?? this.title,
    content: content ?? this.content,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    status: status ?? this.status,
    editorMode: editorMode ?? this.editorMode,
    isLocked: isLocked ?? this.isLocked,
    tags: tags ?? this.tags,
    inquiryQuestion: inquiryQuestion.present
        ? inquiryQuestion.value
        : this.inquiryQuestion,
    inquiryConclusion: inquiryConclusion.present
        ? inquiryConclusion.value
        : this.inquiryConclusion,
    exploreTasks: exploreTasks ?? this.exploreTasks,
    contentFormat: contentFormat ?? this.contentFormat,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  Note copyWithCompanion(NotesCompanion data) {
    return Note(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      status: data.status.present ? data.status.value : this.status,
      editorMode: data.editorMode.present
          ? data.editorMode.value
          : this.editorMode,
      isLocked: data.isLocked.present ? data.isLocked.value : this.isLocked,
      tags: data.tags.present ? data.tags.value : this.tags,
      inquiryQuestion: data.inquiryQuestion.present
          ? data.inquiryQuestion.value
          : this.inquiryQuestion,
      inquiryConclusion: data.inquiryConclusion.present
          ? data.inquiryConclusion.value
          : this.inquiryConclusion,
      exploreTasks: data.exploreTasks.present
          ? data.exploreTasks.value
          : this.exploreTasks,
      contentFormat: data.contentFormat.present
          ? data.contentFormat.value
          : this.contentFormat,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Note(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('status: $status, ')
          ..write('editorMode: $editorMode, ')
          ..write('isLocked: $isLocked, ')
          ..write('tags: $tags, ')
          ..write('inquiryQuestion: $inquiryQuestion, ')
          ..write('inquiryConclusion: $inquiryConclusion, ')
          ..write('exploreTasks: $exploreTasks, ')
          ..write('contentFormat: $contentFormat, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    content,
    updatedAt,
    status,
    editorMode,
    isLocked,
    tags,
    inquiryQuestion,
    inquiryConclusion,
    exploreTasks,
    contentFormat,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Note &&
          other.id == this.id &&
          other.title == this.title &&
          other.content == this.content &&
          other.updatedAt == this.updatedAt &&
          other.status == this.status &&
          other.editorMode == this.editorMode &&
          other.isLocked == this.isLocked &&
          other.tags == this.tags &&
          other.inquiryQuestion == this.inquiryQuestion &&
          other.inquiryConclusion == this.inquiryConclusion &&
          other.exploreTasks == this.exploreTasks &&
          other.contentFormat == this.contentFormat &&
          other.createdAt == this.createdAt);
}

class NotesCompanion extends UpdateCompanion<Note> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> content;
  final Value<String?> updatedAt;
  final Value<String> status;
  final Value<String> editorMode;
  final Value<int> isLocked;
  final Value<String> tags;
  final Value<String?> inquiryQuestion;
  final Value<String?> inquiryConclusion;
  final Value<String> exploreTasks;
  final Value<String> contentFormat;
  final Value<String?> createdAt;
  final Value<int> rowid;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.editorMode = const Value.absent(),
    this.isLocked = const Value.absent(),
    this.tags = const Value.absent(),
    this.inquiryQuestion = const Value.absent(),
    this.inquiryConclusion = const Value.absent(),
    this.exploreTasks = const Value.absent(),
    this.contentFormat = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotesCompanion.insert({
    required String id,
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.editorMode = const Value.absent(),
    this.isLocked = const Value.absent(),
    this.tags = const Value.absent(),
    this.inquiryQuestion = const Value.absent(),
    this.inquiryConclusion = const Value.absent(),
    this.exploreTasks = const Value.absent(),
    this.contentFormat = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<Note> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? content,
    Expression<String>? updatedAt,
    Expression<String>? status,
    Expression<String>? editorMode,
    Expression<int>? isLocked,
    Expression<String>? tags,
    Expression<String>? inquiryQuestion,
    Expression<String>? inquiryConclusion,
    Expression<String>? exploreTasks,
    Expression<String>? contentFormat,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (status != null) 'status': status,
      if (editorMode != null) 'editor_mode': editorMode,
      if (isLocked != null) 'is_locked': isLocked,
      if (tags != null) 'tags': tags,
      if (inquiryQuestion != null) 'inquiry_question': inquiryQuestion,
      if (inquiryConclusion != null) 'inquiry_conclusion': inquiryConclusion,
      if (exploreTasks != null) 'explore_tasks': exploreTasks,
      if (contentFormat != null) 'content_format': contentFormat,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotesCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? content,
    Value<String?>? updatedAt,
    Value<String>? status,
    Value<String>? editorMode,
    Value<int>? isLocked,
    Value<String>? tags,
    Value<String?>? inquiryQuestion,
    Value<String?>? inquiryConclusion,
    Value<String>? exploreTasks,
    Value<String>? contentFormat,
    Value<String?>? createdAt,
    Value<int>? rowid,
  }) {
    return NotesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      editorMode: editorMode ?? this.editorMode,
      isLocked: isLocked ?? this.isLocked,
      tags: tags ?? this.tags,
      inquiryQuestion: inquiryQuestion ?? this.inquiryQuestion,
      inquiryConclusion: inquiryConclusion ?? this.inquiryConclusion,
      exploreTasks: exploreTasks ?? this.exploreTasks,
      contentFormat: contentFormat ?? this.contentFormat,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (editorMode.present) {
      map['editor_mode'] = Variable<String>(editorMode.value);
    }
    if (isLocked.present) {
      map['is_locked'] = Variable<int>(isLocked.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (inquiryQuestion.present) {
      map['inquiry_question'] = Variable<String>(inquiryQuestion.value);
    }
    if (inquiryConclusion.present) {
      map['inquiry_conclusion'] = Variable<String>(inquiryConclusion.value);
    }
    if (exploreTasks.present) {
      map['explore_tasks'] = Variable<String>(exploreTasks.value);
    }
    if (contentFormat.present) {
      map['content_format'] = Variable<String>(contentFormat.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('status: $status, ')
          ..write('editorMode: $editorMode, ')
          ..write('isLocked: $isLocked, ')
          ..write('tags: $tags, ')
          ..write('inquiryQuestion: $inquiryQuestion, ')
          ..write('inquiryConclusion: $inquiryConclusion, ')
          ..write('exploreTasks: $exploreTasks, ')
          ..write('contentFormat: $contentFormat, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NodesTable extends Nodes with TableInfo<$NodesTable, NodeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFolderMeta = const VerificationMeta(
    'isFolder',
  );
  @override
  late final GeneratedColumn<bool> isFolder = GeneratedColumn<bool>(
    'is_folder',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_folder" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _nodeTypeMeta = const VerificationMeta(
    'nodeType',
  );
  @override
  late final GeneratedColumn<String> nodeType = GeneratedColumn<String>(
    'node_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('folder'),
  );
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  @override
  late final GeneratedColumn<String> targetId = GeneratedColumn<String>(
    'target_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _systemTagMeta = const VerificationMeta(
    'systemTag',
  );
  @override
  late final GeneratedColumn<String> systemTag = GeneratedColumn<String>(
    'system_tag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    parentId,
    isFolder,
    nodeType,
    targetId,
    sortOrder,
    tags,
    systemTag,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nodes';
  @override
  VerificationContext validateIntegrity(
    Insertable<NodeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('is_folder')) {
      context.handle(
        _isFolderMeta,
        isFolder.isAcceptableOrUnknown(data['is_folder']!, _isFolderMeta),
      );
    }
    if (data.containsKey('node_type')) {
      context.handle(
        _nodeTypeMeta,
        nodeType.isAcceptableOrUnknown(data['node_type']!, _nodeTypeMeta),
      );
    }
    if (data.containsKey('target_id')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('system_tag')) {
      context.handle(
        _systemTagMeta,
        systemTag.isAcceptableOrUnknown(data['system_tag']!, _systemTagMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NodeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NodeRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      isFolder: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_folder'],
      )!,
      nodeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_type'],
      )!,
      targetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_id'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      systemTag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}system_tag'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $NodesTable createAlias(String alias) {
    return $NodesTable(attachedDatabase, alias);
  }
}

class NodeRow extends DataClass implements Insertable<NodeRow> {
  final String id;
  final String title;
  final String? parentId;
  final bool isFolder;
  final String nodeType;
  final String? targetId;
  final int sortOrder;
  final String tags;
  final String? systemTag;
  final String? createdAt;
  final String? updatedAt;
  const NodeRow({
    required this.id,
    required this.title,
    this.parentId,
    required this.isFolder,
    required this.nodeType,
    this.targetId,
    required this.sortOrder,
    required this.tags,
    this.systemTag,
    this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['is_folder'] = Variable<bool>(isFolder);
    map['node_type'] = Variable<String>(nodeType);
    if (!nullToAbsent || targetId != null) {
      map['target_id'] = Variable<String>(targetId);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['tags'] = Variable<String>(tags);
    if (!nullToAbsent || systemTag != null) {
      map['system_tag'] = Variable<String>(systemTag);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    return map;
  }

  NodesCompanion toCompanion(bool nullToAbsent) {
    return NodesCompanion(
      id: Value(id),
      title: Value(title),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      isFolder: Value(isFolder),
      nodeType: Value(nodeType),
      targetId: targetId == null && nullToAbsent
          ? const Value.absent()
          : Value(targetId),
      sortOrder: Value(sortOrder),
      tags: Value(tags),
      systemTag: systemTag == null && nullToAbsent
          ? const Value.absent()
          : Value(systemTag),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory NodeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NodeRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      isFolder: serializer.fromJson<bool>(json['isFolder']),
      nodeType: serializer.fromJson<String>(json['nodeType']),
      targetId: serializer.fromJson<String?>(json['targetId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      tags: serializer.fromJson<String>(json['tags']),
      systemTag: serializer.fromJson<String?>(json['systemTag']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'parentId': serializer.toJson<String?>(parentId),
      'isFolder': serializer.toJson<bool>(isFolder),
      'nodeType': serializer.toJson<String>(nodeType),
      'targetId': serializer.toJson<String?>(targetId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'tags': serializer.toJson<String>(tags),
      'systemTag': serializer.toJson<String?>(systemTag),
      'createdAt': serializer.toJson<String?>(createdAt),
      'updatedAt': serializer.toJson<String?>(updatedAt),
    };
  }

  NodeRow copyWith({
    String? id,
    String? title,
    Value<String?> parentId = const Value.absent(),
    bool? isFolder,
    String? nodeType,
    Value<String?> targetId = const Value.absent(),
    int? sortOrder,
    String? tags,
    Value<String?> systemTag = const Value.absent(),
    Value<String?> createdAt = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
  }) => NodeRow(
    id: id ?? this.id,
    title: title ?? this.title,
    parentId: parentId.present ? parentId.value : this.parentId,
    isFolder: isFolder ?? this.isFolder,
    nodeType: nodeType ?? this.nodeType,
    targetId: targetId.present ? targetId.value : this.targetId,
    sortOrder: sortOrder ?? this.sortOrder,
    tags: tags ?? this.tags,
    systemTag: systemTag.present ? systemTag.value : this.systemTag,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  NodeRow copyWithCompanion(NodesCompanion data) {
    return NodeRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      isFolder: data.isFolder.present ? data.isFolder.value : this.isFolder,
      nodeType: data.nodeType.present ? data.nodeType.value : this.nodeType,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      tags: data.tags.present ? data.tags.value : this.tags,
      systemTag: data.systemTag.present ? data.systemTag.value : this.systemTag,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NodeRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('parentId: $parentId, ')
          ..write('isFolder: $isFolder, ')
          ..write('nodeType: $nodeType, ')
          ..write('targetId: $targetId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('tags: $tags, ')
          ..write('systemTag: $systemTag, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    parentId,
    isFolder,
    nodeType,
    targetId,
    sortOrder,
    tags,
    systemTag,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NodeRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.parentId == this.parentId &&
          other.isFolder == this.isFolder &&
          other.nodeType == this.nodeType &&
          other.targetId == this.targetId &&
          other.sortOrder == this.sortOrder &&
          other.tags == this.tags &&
          other.systemTag == this.systemTag &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class NodesCompanion extends UpdateCompanion<NodeRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> parentId;
  final Value<bool> isFolder;
  final Value<String> nodeType;
  final Value<String?> targetId;
  final Value<int> sortOrder;
  final Value<String> tags;
  final Value<String?> systemTag;
  final Value<String?> createdAt;
  final Value<String?> updatedAt;
  final Value<int> rowid;
  const NodesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.parentId = const Value.absent(),
    this.isFolder = const Value.absent(),
    this.nodeType = const Value.absent(),
    this.targetId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.tags = const Value.absent(),
    this.systemTag = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NodesCompanion.insert({
    required String id,
    this.title = const Value.absent(),
    this.parentId = const Value.absent(),
    this.isFolder = const Value.absent(),
    this.nodeType = const Value.absent(),
    this.targetId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.tags = const Value.absent(),
    this.systemTag = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<NodeRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? parentId,
    Expression<bool>? isFolder,
    Expression<String>? nodeType,
    Expression<String>? targetId,
    Expression<int>? sortOrder,
    Expression<String>? tags,
    Expression<String>? systemTag,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (parentId != null) 'parent_id': parentId,
      if (isFolder != null) 'is_folder': isFolder,
      if (nodeType != null) 'node_type': nodeType,
      if (targetId != null) 'target_id': targetId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (tags != null) 'tags': tags,
      if (systemTag != null) 'system_tag': systemTag,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NodesCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? parentId,
    Value<bool>? isFolder,
    Value<String>? nodeType,
    Value<String?>? targetId,
    Value<int>? sortOrder,
    Value<String>? tags,
    Value<String?>? systemTag,
    Value<String?>? createdAt,
    Value<String?>? updatedAt,
    Value<int>? rowid,
  }) {
    return NodesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      parentId: parentId ?? this.parentId,
      isFolder: isFolder ?? this.isFolder,
      nodeType: nodeType ?? this.nodeType,
      targetId: targetId ?? this.targetId,
      sortOrder: sortOrder ?? this.sortOrder,
      tags: tags ?? this.tags,
      systemTag: systemTag ?? this.systemTag,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (isFolder.present) {
      map['is_folder'] = Variable<bool>(isFolder.value);
    }
    if (nodeType.present) {
      map['node_type'] = Variable<String>(nodeType.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<String>(targetId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (systemTag.present) {
      map['system_tag'] = Variable<String>(systemTag.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NodesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('parentId: $parentId, ')
          ..write('isFolder: $isFolder, ')
          ..write('nodeType: $nodeType, ')
          ..write('targetId: $targetId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('tags: $tags, ')
          ..write('systemTag: $systemTag, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BooksTable extends Books with TableInfo<$BooksTable, BookRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isbnMeta = const VerificationMeta('isbn');
  @override
  late final GeneratedColumn<String> isbn = GeneratedColumn<String>(
    'isbn',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _coverUrlMeta = const VerificationMeta(
    'coverUrl',
  );
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
    'cover_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileTypeMeta = const VerificationMeta(
    'fileType',
  );
  @override
  late final GeneratedColumn<String> fileType = GeneratedColumn<String>(
    'file_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('want'),
  );
  static const VerificationMeta _readingProgressMeta = const VerificationMeta(
    'readingProgress',
  );
  @override
  late final GeneratedColumn<int> readingProgress = GeneratedColumn<int>(
    'reading_progress',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalPagesMeta = const VerificationMeta(
    'totalPages',
  );
  @override
  late final GeneratedColumn<int> totalPages = GeneratedColumn<int>(
    'total_pages',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastReadAtMeta = const VerificationMeta(
    'lastReadAt',
  );
  @override
  late final GeneratedColumn<String> lastReadAt = GeneratedColumn<String>(
    'last_read_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
    'rating',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reviewMeta = const VerificationMeta('review');
  @override
  late final GeneratedColumn<String> review = GeneratedColumn<String>(
    'review',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    author,
    isbn,
    coverUrl,
    filePath,
    fileType,
    fileName,
    fileSize,
    status,
    readingProgress,
    totalPages,
    createdAt,
    lastReadAt,
    source,
    summary,
    rating,
    review,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'books';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('isbn')) {
      context.handle(
        _isbnMeta,
        isbn.isAcceptableOrUnknown(data['isbn']!, _isbnMeta),
      );
    }
    if (data.containsKey('cover_url')) {
      context.handle(
        _coverUrlMeta,
        coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta),
      );
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    }
    if (data.containsKey('file_type')) {
      context.handle(
        _fileTypeMeta,
        fileType.isAcceptableOrUnknown(data['file_type']!, _fileTypeMeta),
      );
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('reading_progress')) {
      context.handle(
        _readingProgressMeta,
        readingProgress.isAcceptableOrUnknown(
          data['reading_progress']!,
          _readingProgressMeta,
        ),
      );
    }
    if (data.containsKey('total_pages')) {
      context.handle(
        _totalPagesMeta,
        totalPages.isAcceptableOrUnknown(data['total_pages']!, _totalPagesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('last_read_at')) {
      context.handle(
        _lastReadAtMeta,
        lastReadAt.isAcceptableOrUnknown(
          data['last_read_at']!,
          _lastReadAtMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('review')) {
      context.handle(
        _reviewMeta,
        review.isAcceptableOrUnknown(data['review']!, _reviewMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BookRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      )!,
      isbn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}isbn'],
      )!,
      coverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_url'],
      ),
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      ),
      fileType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_type'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      ),
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      readingProgress: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reading_progress'],
      )!,
      totalPages: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_pages'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
      lastReadAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_read_at'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      ),
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rating'],
      ),
      review: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}review'],
      ),
    );
  }

  @override
  $BooksTable createAlias(String alias) {
    return $BooksTable(attachedDatabase, alias);
  }
}

class BookRow extends DataClass implements Insertable<BookRow> {
  final String id;
  final String title;
  final String author;
  final String isbn;
  final String? coverUrl;
  final String? filePath;
  final String fileType;
  final String? fileName;
  final int fileSize;
  final String status;
  final int readingProgress;
  final int totalPages;
  final String? createdAt;
  final String? lastReadAt;
  final String source;
  final String? summary;
  final double? rating;
  final String? review;
  const BookRow({
    required this.id,
    required this.title,
    required this.author,
    required this.isbn,
    this.coverUrl,
    this.filePath,
    required this.fileType,
    this.fileName,
    required this.fileSize,
    required this.status,
    required this.readingProgress,
    required this.totalPages,
    this.createdAt,
    this.lastReadAt,
    required this.source,
    this.summary,
    this.rating,
    this.review,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['author'] = Variable<String>(author);
    map['isbn'] = Variable<String>(isbn);
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = Variable<String>(coverUrl);
    }
    if (!nullToAbsent || filePath != null) {
      map['file_path'] = Variable<String>(filePath);
    }
    map['file_type'] = Variable<String>(fileType);
    if (!nullToAbsent || fileName != null) {
      map['file_name'] = Variable<String>(fileName);
    }
    map['file_size'] = Variable<int>(fileSize);
    map['status'] = Variable<String>(status);
    map['reading_progress'] = Variable<int>(readingProgress);
    map['total_pages'] = Variable<int>(totalPages);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || lastReadAt != null) {
      map['last_read_at'] = Variable<String>(lastReadAt);
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || summary != null) {
      map['summary'] = Variable<String>(summary);
    }
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<double>(rating);
    }
    if (!nullToAbsent || review != null) {
      map['review'] = Variable<String>(review);
    }
    return map;
  }

  BooksCompanion toCompanion(bool nullToAbsent) {
    return BooksCompanion(
      id: Value(id),
      title: Value(title),
      author: Value(author),
      isbn: Value(isbn),
      coverUrl: coverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUrl),
      filePath: filePath == null && nullToAbsent
          ? const Value.absent()
          : Value(filePath),
      fileType: Value(fileType),
      fileName: fileName == null && nullToAbsent
          ? const Value.absent()
          : Value(fileName),
      fileSize: Value(fileSize),
      status: Value(status),
      readingProgress: Value(readingProgress),
      totalPages: Value(totalPages),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      lastReadAt: lastReadAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReadAt),
      source: Value(source),
      summary: summary == null && nullToAbsent
          ? const Value.absent()
          : Value(summary),
      rating: rating == null && nullToAbsent
          ? const Value.absent()
          : Value(rating),
      review: review == null && nullToAbsent
          ? const Value.absent()
          : Value(review),
    );
  }

  factory BookRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      author: serializer.fromJson<String>(json['author']),
      isbn: serializer.fromJson<String>(json['isbn']),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
      filePath: serializer.fromJson<String?>(json['filePath']),
      fileType: serializer.fromJson<String>(json['fileType']),
      fileName: serializer.fromJson<String?>(json['fileName']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      status: serializer.fromJson<String>(json['status']),
      readingProgress: serializer.fromJson<int>(json['readingProgress']),
      totalPages: serializer.fromJson<int>(json['totalPages']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
      lastReadAt: serializer.fromJson<String?>(json['lastReadAt']),
      source: serializer.fromJson<String>(json['source']),
      summary: serializer.fromJson<String?>(json['summary']),
      rating: serializer.fromJson<double?>(json['rating']),
      review: serializer.fromJson<String?>(json['review']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'author': serializer.toJson<String>(author),
      'isbn': serializer.toJson<String>(isbn),
      'coverUrl': serializer.toJson<String?>(coverUrl),
      'filePath': serializer.toJson<String?>(filePath),
      'fileType': serializer.toJson<String>(fileType),
      'fileName': serializer.toJson<String?>(fileName),
      'fileSize': serializer.toJson<int>(fileSize),
      'status': serializer.toJson<String>(status),
      'readingProgress': serializer.toJson<int>(readingProgress),
      'totalPages': serializer.toJson<int>(totalPages),
      'createdAt': serializer.toJson<String?>(createdAt),
      'lastReadAt': serializer.toJson<String?>(lastReadAt),
      'source': serializer.toJson<String>(source),
      'summary': serializer.toJson<String?>(summary),
      'rating': serializer.toJson<double?>(rating),
      'review': serializer.toJson<String?>(review),
    };
  }

  BookRow copyWith({
    String? id,
    String? title,
    String? author,
    String? isbn,
    Value<String?> coverUrl = const Value.absent(),
    Value<String?> filePath = const Value.absent(),
    String? fileType,
    Value<String?> fileName = const Value.absent(),
    int? fileSize,
    String? status,
    int? readingProgress,
    int? totalPages,
    Value<String?> createdAt = const Value.absent(),
    Value<String?> lastReadAt = const Value.absent(),
    String? source,
    Value<String?> summary = const Value.absent(),
    Value<double?> rating = const Value.absent(),
    Value<String?> review = const Value.absent(),
  }) => BookRow(
    id: id ?? this.id,
    title: title ?? this.title,
    author: author ?? this.author,
    isbn: isbn ?? this.isbn,
    coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
    filePath: filePath.present ? filePath.value : this.filePath,
    fileType: fileType ?? this.fileType,
    fileName: fileName.present ? fileName.value : this.fileName,
    fileSize: fileSize ?? this.fileSize,
    status: status ?? this.status,
    readingProgress: readingProgress ?? this.readingProgress,
    totalPages: totalPages ?? this.totalPages,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    lastReadAt: lastReadAt.present ? lastReadAt.value : this.lastReadAt,
    source: source ?? this.source,
    summary: summary.present ? summary.value : this.summary,
    rating: rating.present ? rating.value : this.rating,
    review: review.present ? review.value : this.review,
  );
  BookRow copyWithCompanion(BooksCompanion data) {
    return BookRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      author: data.author.present ? data.author.value : this.author,
      isbn: data.isbn.present ? data.isbn.value : this.isbn,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      fileType: data.fileType.present ? data.fileType.value : this.fileType,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      status: data.status.present ? data.status.value : this.status,
      readingProgress: data.readingProgress.present
          ? data.readingProgress.value
          : this.readingProgress,
      totalPages: data.totalPages.present
          ? data.totalPages.value
          : this.totalPages,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastReadAt: data.lastReadAt.present
          ? data.lastReadAt.value
          : this.lastReadAt,
      source: data.source.present ? data.source.value : this.source,
      summary: data.summary.present ? data.summary.value : this.summary,
      rating: data.rating.present ? data.rating.value : this.rating,
      review: data.review.present ? data.review.value : this.review,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('isbn: $isbn, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('filePath: $filePath, ')
          ..write('fileType: $fileType, ')
          ..write('fileName: $fileName, ')
          ..write('fileSize: $fileSize, ')
          ..write('status: $status, ')
          ..write('readingProgress: $readingProgress, ')
          ..write('totalPages: $totalPages, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastReadAt: $lastReadAt, ')
          ..write('source: $source, ')
          ..write('summary: $summary, ')
          ..write('rating: $rating, ')
          ..write('review: $review')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    author,
    isbn,
    coverUrl,
    filePath,
    fileType,
    fileName,
    fileSize,
    status,
    readingProgress,
    totalPages,
    createdAt,
    lastReadAt,
    source,
    summary,
    rating,
    review,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.author == this.author &&
          other.isbn == this.isbn &&
          other.coverUrl == this.coverUrl &&
          other.filePath == this.filePath &&
          other.fileType == this.fileType &&
          other.fileName == this.fileName &&
          other.fileSize == this.fileSize &&
          other.status == this.status &&
          other.readingProgress == this.readingProgress &&
          other.totalPages == this.totalPages &&
          other.createdAt == this.createdAt &&
          other.lastReadAt == this.lastReadAt &&
          other.source == this.source &&
          other.summary == this.summary &&
          other.rating == this.rating &&
          other.review == this.review);
}

class BooksCompanion extends UpdateCompanion<BookRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> author;
  final Value<String> isbn;
  final Value<String?> coverUrl;
  final Value<String?> filePath;
  final Value<String> fileType;
  final Value<String?> fileName;
  final Value<int> fileSize;
  final Value<String> status;
  final Value<int> readingProgress;
  final Value<int> totalPages;
  final Value<String?> createdAt;
  final Value<String?> lastReadAt;
  final Value<String> source;
  final Value<String?> summary;
  final Value<double?> rating;
  final Value<String?> review;
  final Value<int> rowid;
  const BooksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.isbn = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.filePath = const Value.absent(),
    this.fileType = const Value.absent(),
    this.fileName = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.status = const Value.absent(),
    this.readingProgress = const Value.absent(),
    this.totalPages = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastReadAt = const Value.absent(),
    this.source = const Value.absent(),
    this.summary = const Value.absent(),
    this.rating = const Value.absent(),
    this.review = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BooksCompanion.insert({
    required String id,
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.isbn = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.filePath = const Value.absent(),
    this.fileType = const Value.absent(),
    this.fileName = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.status = const Value.absent(),
    this.readingProgress = const Value.absent(),
    this.totalPages = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastReadAt = const Value.absent(),
    this.source = const Value.absent(),
    this.summary = const Value.absent(),
    this.rating = const Value.absent(),
    this.review = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<BookRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? author,
    Expression<String>? isbn,
    Expression<String>? coverUrl,
    Expression<String>? filePath,
    Expression<String>? fileType,
    Expression<String>? fileName,
    Expression<int>? fileSize,
    Expression<String>? status,
    Expression<int>? readingProgress,
    Expression<int>? totalPages,
    Expression<String>? createdAt,
    Expression<String>? lastReadAt,
    Expression<String>? source,
    Expression<String>? summary,
    Expression<double>? rating,
    Expression<String>? review,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (isbn != null) 'isbn': isbn,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (filePath != null) 'file_path': filePath,
      if (fileType != null) 'file_type': fileType,
      if (fileName != null) 'file_name': fileName,
      if (fileSize != null) 'file_size': fileSize,
      if (status != null) 'status': status,
      if (readingProgress != null) 'reading_progress': readingProgress,
      if (totalPages != null) 'total_pages': totalPages,
      if (createdAt != null) 'created_at': createdAt,
      if (lastReadAt != null) 'last_read_at': lastReadAt,
      if (source != null) 'source': source,
      if (summary != null) 'summary': summary,
      if (rating != null) 'rating': rating,
      if (review != null) 'review': review,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BooksCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? author,
    Value<String>? isbn,
    Value<String?>? coverUrl,
    Value<String?>? filePath,
    Value<String>? fileType,
    Value<String?>? fileName,
    Value<int>? fileSize,
    Value<String>? status,
    Value<int>? readingProgress,
    Value<int>? totalPages,
    Value<String?>? createdAt,
    Value<String?>? lastReadAt,
    Value<String>? source,
    Value<String?>? summary,
    Value<double?>? rating,
    Value<String?>? review,
    Value<int>? rowid,
  }) {
    return BooksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      isbn: isbn ?? this.isbn,
      coverUrl: coverUrl ?? this.coverUrl,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      status: status ?? this.status,
      readingProgress: readingProgress ?? this.readingProgress,
      totalPages: totalPages ?? this.totalPages,
      createdAt: createdAt ?? this.createdAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      source: source ?? this.source,
      summary: summary ?? this.summary,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (isbn.present) {
      map['isbn'] = Variable<String>(isbn.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (fileType.present) {
      map['file_type'] = Variable<String>(fileType.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (readingProgress.present) {
      map['reading_progress'] = Variable<int>(readingProgress.value);
    }
    if (totalPages.present) {
      map['total_pages'] = Variable<int>(totalPages.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (lastReadAt.present) {
      map['last_read_at'] = Variable<String>(lastReadAt.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (review.present) {
      map['review'] = Variable<String>(review.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BooksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('isbn: $isbn, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('filePath: $filePath, ')
          ..write('fileType: $fileType, ')
          ..write('fileName: $fileName, ')
          ..write('fileSize: $fileSize, ')
          ..write('status: $status, ')
          ..write('readingProgress: $readingProgress, ')
          ..write('totalPages: $totalPages, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastReadAt: $lastReadAt, ')
          ..write('source: $source, ')
          ..write('summary: $summary, ')
          ..write('rating: $rating, ')
          ..write('review: $review, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BookAnnotationsTable extends BookAnnotations
    with TableInfo<$BookAnnotationsTable, BookAnnotation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookAnnotationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pageNumberMeta = const VerificationMeta(
    'pageNumber',
  );
  @override
  late final GeneratedColumn<int> pageNumber = GeneratedColumn<int>(
    'page_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quoteMeta = const VerificationMeta('quote');
  @override
  late final GeneratedColumn<String> quote = GeneratedColumn<String>(
    'quote',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bookId,
    pageNumber,
    quote,
    note,
    color,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'book_annotations';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookAnnotation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    }
    if (data.containsKey('page_number')) {
      context.handle(
        _pageNumberMeta,
        pageNumber.isAcceptableOrUnknown(data['page_number']!, _pageNumberMeta),
      );
    }
    if (data.containsKey('quote')) {
      context.handle(
        _quoteMeta,
        quote.isAcceptableOrUnknown(data['quote']!, _quoteMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BookAnnotation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookAnnotation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      ),
      pageNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_number'],
      ),
      quote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quote'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $BookAnnotationsTable createAlias(String alias) {
    return $BookAnnotationsTable(attachedDatabase, alias);
  }
}

class BookAnnotation extends DataClass implements Insertable<BookAnnotation> {
  final String id;
  final String? bookId;
  final int? pageNumber;
  final String? quote;
  final String? note;
  final String? color;
  final String? createdAt;
  const BookAnnotation({
    required this.id,
    this.bookId,
    this.pageNumber,
    this.quote,
    this.note,
    this.color,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || bookId != null) {
      map['book_id'] = Variable<String>(bookId);
    }
    if (!nullToAbsent || pageNumber != null) {
      map['page_number'] = Variable<int>(pageNumber);
    }
    if (!nullToAbsent || quote != null) {
      map['quote'] = Variable<String>(quote);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    return map;
  }

  BookAnnotationsCompanion toCompanion(bool nullToAbsent) {
    return BookAnnotationsCompanion(
      id: Value(id),
      bookId: bookId == null && nullToAbsent
          ? const Value.absent()
          : Value(bookId),
      pageNumber: pageNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(pageNumber),
      quote: quote == null && nullToAbsent
          ? const Value.absent()
          : Value(quote),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory BookAnnotation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookAnnotation(
      id: serializer.fromJson<String>(json['id']),
      bookId: serializer.fromJson<String?>(json['bookId']),
      pageNumber: serializer.fromJson<int?>(json['pageNumber']),
      quote: serializer.fromJson<String?>(json['quote']),
      note: serializer.fromJson<String?>(json['note']),
      color: serializer.fromJson<String?>(json['color']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bookId': serializer.toJson<String?>(bookId),
      'pageNumber': serializer.toJson<int?>(pageNumber),
      'quote': serializer.toJson<String?>(quote),
      'note': serializer.toJson<String?>(note),
      'color': serializer.toJson<String?>(color),
      'createdAt': serializer.toJson<String?>(createdAt),
    };
  }

  BookAnnotation copyWith({
    String? id,
    Value<String?> bookId = const Value.absent(),
    Value<int?> pageNumber = const Value.absent(),
    Value<String?> quote = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<String?> color = const Value.absent(),
    Value<String?> createdAt = const Value.absent(),
  }) => BookAnnotation(
    id: id ?? this.id,
    bookId: bookId.present ? bookId.value : this.bookId,
    pageNumber: pageNumber.present ? pageNumber.value : this.pageNumber,
    quote: quote.present ? quote.value : this.quote,
    note: note.present ? note.value : this.note,
    color: color.present ? color.value : this.color,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  BookAnnotation copyWithCompanion(BookAnnotationsCompanion data) {
    return BookAnnotation(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      pageNumber: data.pageNumber.present
          ? data.pageNumber.value
          : this.pageNumber,
      quote: data.quote.present ? data.quote.value : this.quote,
      note: data.note.present ? data.note.value : this.note,
      color: data.color.present ? data.color.value : this.color,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookAnnotation(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('quote: $quote, ')
          ..write('note: $note, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, bookId, pageNumber, quote, note, color, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookAnnotation &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.pageNumber == this.pageNumber &&
          other.quote == this.quote &&
          other.note == this.note &&
          other.color == this.color &&
          other.createdAt == this.createdAt);
}

class BookAnnotationsCompanion extends UpdateCompanion<BookAnnotation> {
  final Value<String> id;
  final Value<String?> bookId;
  final Value<int?> pageNumber;
  final Value<String?> quote;
  final Value<String?> note;
  final Value<String?> color;
  final Value<String?> createdAt;
  final Value<int> rowid;
  const BookAnnotationsCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.pageNumber = const Value.absent(),
    this.quote = const Value.absent(),
    this.note = const Value.absent(),
    this.color = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookAnnotationsCompanion.insert({
    required String id,
    this.bookId = const Value.absent(),
    this.pageNumber = const Value.absent(),
    this.quote = const Value.absent(),
    this.note = const Value.absent(),
    this.color = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<BookAnnotation> custom({
    Expression<String>? id,
    Expression<String>? bookId,
    Expression<int>? pageNumber,
    Expression<String>? quote,
    Expression<String>? note,
    Expression<String>? color,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (pageNumber != null) 'page_number': pageNumber,
      if (quote != null) 'quote': quote,
      if (note != null) 'note': note,
      if (color != null) 'color': color,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookAnnotationsCompanion copyWith({
    Value<String>? id,
    Value<String?>? bookId,
    Value<int?>? pageNumber,
    Value<String?>? quote,
    Value<String?>? note,
    Value<String?>? color,
    Value<String?>? createdAt,
    Value<int>? rowid,
  }) {
    return BookAnnotationsCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      pageNumber: pageNumber ?? this.pageNumber,
      quote: quote ?? this.quote,
      note: note ?? this.note,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (pageNumber.present) {
      map['page_number'] = Variable<int>(pageNumber.value);
    }
    if (quote.present) {
      map['quote'] = Variable<String>(quote.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookAnnotationsCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('quote: $quote, ')
          ..write('note: $note, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BookHighlightsTable extends BookHighlights
    with TableInfo<$BookHighlightsTable, BookHighlightRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookHighlightsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _chapterMeta = const VerificationMeta(
    'chapter',
  );
  @override
  late final GeneratedColumn<String> chapter = GeneratedColumn<String>(
    'chapter',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _textContentMeta = const VerificationMeta(
    'textContent',
  );
  @override
  late final GeneratedColumn<String> textContent = GeneratedColumn<String>(
    'text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bookId,
    chapter,
    location,
    textContent,
    color,
    note,
    createdAt,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'book_highlights';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookHighlightRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    }
    if (data.containsKey('chapter')) {
      context.handle(
        _chapterMeta,
        chapter.isAcceptableOrUnknown(data['chapter']!, _chapterMeta),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('text')) {
      context.handle(
        _textContentMeta,
        textContent.isAcceptableOrUnknown(data['text']!, _textContentMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BookHighlightRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookHighlightRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      ),
      chapter: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chapter'],
      ),
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      textContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      ),
    );
  }

  @override
  $BookHighlightsTable createAlias(String alias) {
    return $BookHighlightsTable(attachedDatabase, alias);
  }
}

class BookHighlightRow extends DataClass
    implements Insertable<BookHighlightRow> {
  final String id;
  final String? bookId;
  final String? chapter;
  final String? location;
  final String? textContent;
  final String? color;
  final String? note;
  final String? createdAt;
  final String? source;
  const BookHighlightRow({
    required this.id,
    this.bookId,
    this.chapter,
    this.location,
    this.textContent,
    this.color,
    this.note,
    this.createdAt,
    this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || bookId != null) {
      map['book_id'] = Variable<String>(bookId);
    }
    if (!nullToAbsent || chapter != null) {
      map['chapter'] = Variable<String>(chapter);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || textContent != null) {
      map['text'] = Variable<String>(textContent);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    return map;
  }

  BookHighlightsCompanion toCompanion(bool nullToAbsent) {
    return BookHighlightsCompanion(
      id: Value(id),
      bookId: bookId == null && nullToAbsent
          ? const Value.absent()
          : Value(bookId),
      chapter: chapter == null && nullToAbsent
          ? const Value.absent()
          : Value(chapter),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      textContent: textContent == null && nullToAbsent
          ? const Value.absent()
          : Value(textContent),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      source: source == null && nullToAbsent
          ? const Value.absent()
          : Value(source),
    );
  }

  factory BookHighlightRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookHighlightRow(
      id: serializer.fromJson<String>(json['id']),
      bookId: serializer.fromJson<String?>(json['bookId']),
      chapter: serializer.fromJson<String?>(json['chapter']),
      location: serializer.fromJson<String?>(json['location']),
      textContent: serializer.fromJson<String?>(json['textContent']),
      color: serializer.fromJson<String?>(json['color']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
      source: serializer.fromJson<String?>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bookId': serializer.toJson<String?>(bookId),
      'chapter': serializer.toJson<String?>(chapter),
      'location': serializer.toJson<String?>(location),
      'textContent': serializer.toJson<String?>(textContent),
      'color': serializer.toJson<String?>(color),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<String?>(createdAt),
      'source': serializer.toJson<String?>(source),
    };
  }

  BookHighlightRow copyWith({
    String? id,
    Value<String?> bookId = const Value.absent(),
    Value<String?> chapter = const Value.absent(),
    Value<String?> location = const Value.absent(),
    Value<String?> textContent = const Value.absent(),
    Value<String?> color = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<String?> createdAt = const Value.absent(),
    Value<String?> source = const Value.absent(),
  }) => BookHighlightRow(
    id: id ?? this.id,
    bookId: bookId.present ? bookId.value : this.bookId,
    chapter: chapter.present ? chapter.value : this.chapter,
    location: location.present ? location.value : this.location,
    textContent: textContent.present ? textContent.value : this.textContent,
    color: color.present ? color.value : this.color,
    note: note.present ? note.value : this.note,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    source: source.present ? source.value : this.source,
  );
  BookHighlightRow copyWithCompanion(BookHighlightsCompanion data) {
    return BookHighlightRow(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      chapter: data.chapter.present ? data.chapter.value : this.chapter,
      location: data.location.present ? data.location.value : this.location,
      textContent: data.textContent.present
          ? data.textContent.value
          : this.textContent,
      color: data.color.present ? data.color.value : this.color,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookHighlightRow(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('chapter: $chapter, ')
          ..write('location: $location, ')
          ..write('textContent: $textContent, ')
          ..write('color: $color, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bookId,
    chapter,
    location,
    textContent,
    color,
    note,
    createdAt,
    source,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookHighlightRow &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.chapter == this.chapter &&
          other.location == this.location &&
          other.textContent == this.textContent &&
          other.color == this.color &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.source == this.source);
}

class BookHighlightsCompanion extends UpdateCompanion<BookHighlightRow> {
  final Value<String> id;
  final Value<String?> bookId;
  final Value<String?> chapter;
  final Value<String?> location;
  final Value<String?> textContent;
  final Value<String?> color;
  final Value<String?> note;
  final Value<String?> createdAt;
  final Value<String?> source;
  final Value<int> rowid;
  const BookHighlightsCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.chapter = const Value.absent(),
    this.location = const Value.absent(),
    this.textContent = const Value.absent(),
    this.color = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookHighlightsCompanion.insert({
    required String id,
    this.bookId = const Value.absent(),
    this.chapter = const Value.absent(),
    this.location = const Value.absent(),
    this.textContent = const Value.absent(),
    this.color = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<BookHighlightRow> custom({
    Expression<String>? id,
    Expression<String>? bookId,
    Expression<String>? chapter,
    Expression<String>? location,
    Expression<String>? textContent,
    Expression<String>? color,
    Expression<String>? note,
    Expression<String>? createdAt,
    Expression<String>? source,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (chapter != null) 'chapter': chapter,
      if (location != null) 'location': location,
      if (textContent != null) 'text': textContent,
      if (color != null) 'color': color,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (source != null) 'source': source,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookHighlightsCompanion copyWith({
    Value<String>? id,
    Value<String?>? bookId,
    Value<String?>? chapter,
    Value<String?>? location,
    Value<String?>? textContent,
    Value<String?>? color,
    Value<String?>? note,
    Value<String?>? createdAt,
    Value<String?>? source,
    Value<int>? rowid,
  }) {
    return BookHighlightsCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      chapter: chapter ?? this.chapter,
      location: location ?? this.location,
      textContent: textContent ?? this.textContent,
      color: color ?? this.color,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      source: source ?? this.source,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (chapter.present) {
      map['chapter'] = Variable<String>(chapter.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (textContent.present) {
      map['text'] = Variable<String>(textContent.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookHighlightsCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('chapter: $chapter, ')
          ..write('location: $location, ')
          ..write('textContent: $textContent, ')
          ..write('color: $color, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('source: $source, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BookBookmarksTable extends BookBookmarks
    with TableInfo<$BookBookmarksTable, BookBookmark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookBookmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, bookId, location, note, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'book_bookmarks';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookBookmark> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    } else if (isInserting) {
      context.missing(_locationMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BookBookmark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookBookmark(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $BookBookmarksTable createAlias(String alias) {
    return $BookBookmarksTable(attachedDatabase, alias);
  }
}

class BookBookmark extends DataClass implements Insertable<BookBookmark> {
  final String id;
  final String bookId;
  final String location;
  final String? note;
  final String createdAt;
  const BookBookmark({
    required this.id,
    required this.bookId,
    required this.location,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['book_id'] = Variable<String>(bookId);
    map['location'] = Variable<String>(location);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  BookBookmarksCompanion toCompanion(bool nullToAbsent) {
    return BookBookmarksCompanion(
      id: Value(id),
      bookId: Value(bookId),
      location: Value(location),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory BookBookmark.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookBookmark(
      id: serializer.fromJson<String>(json['id']),
      bookId: serializer.fromJson<String>(json['bookId']),
      location: serializer.fromJson<String>(json['location']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bookId': serializer.toJson<String>(bookId),
      'location': serializer.toJson<String>(location),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  BookBookmark copyWith({
    String? id,
    String? bookId,
    String? location,
    Value<String?> note = const Value.absent(),
    String? createdAt,
  }) => BookBookmark(
    id: id ?? this.id,
    bookId: bookId ?? this.bookId,
    location: location ?? this.location,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  BookBookmark copyWithCompanion(BookBookmarksCompanion data) {
    return BookBookmark(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      location: data.location.present ? data.location.value : this.location,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookBookmark(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('location: $location, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, bookId, location, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookBookmark &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.location == this.location &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class BookBookmarksCompanion extends UpdateCompanion<BookBookmark> {
  final Value<String> id;
  final Value<String> bookId;
  final Value<String> location;
  final Value<String?> note;
  final Value<String> createdAt;
  final Value<int> rowid;
  const BookBookmarksCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.location = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookBookmarksCompanion.insert({
    required String id,
    required String bookId,
    required String location,
    this.note = const Value.absent(),
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       bookId = Value(bookId),
       location = Value(location),
       createdAt = Value(createdAt);
  static Insertable<BookBookmark> custom({
    Expression<String>? id,
    Expression<String>? bookId,
    Expression<String>? location,
    Expression<String>? note,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (location != null) 'location': location,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookBookmarksCompanion copyWith({
    Value<String>? id,
    Value<String>? bookId,
    Value<String>? location,
    Value<String?>? note,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return BookBookmarksCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      location: location ?? this.location,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookBookmarksCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('location: $location, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, TaskRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('quick'),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('medium'),
  );
  static const VerificationMeta _urgencyMeta = const VerificationMeta(
    'urgency',
  );
  @override
  late final GeneratedColumn<String> urgency = GeneratedColumn<String>(
    'urgency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('medium'),
  );
  static const VerificationMeta _necessityMeta = const VerificationMeta(
    'necessity',
  );
  @override
  late final GeneratedColumn<String> necessity = GeneratedColumn<String>(
    'necessity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('important'),
  );
  static const VerificationMeta _isDoneMeta = const VerificationMeta('isDone');
  @override
  late final GeneratedColumn<bool> isDone = GeneratedColumn<bool>(
    'is_done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
    'note_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subtaskIdsMeta = const VerificationMeta(
    'subtaskIds',
  );
  @override
  late final GeneratedColumn<String> subtaskIds = GeneratedColumn<String>(
    'subtask_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _reminderTimeMeta = const VerificationMeta(
    'reminderTime',
  );
  @override
  late final GeneratedColumn<String> reminderTime = GeneratedColumn<String>(
    'reminder_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<String> completedAt = GeneratedColumn<String>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    type,
    description,
    difficulty,
    urgency,
    necessity,
    isDone,
    noteId,
    subtaskIds,
    reminderTime,
    createdAt,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    }
    if (data.containsKey('urgency')) {
      context.handle(
        _urgencyMeta,
        urgency.isAcceptableOrUnknown(data['urgency']!, _urgencyMeta),
      );
    }
    if (data.containsKey('necessity')) {
      context.handle(
        _necessityMeta,
        necessity.isAcceptableOrUnknown(data['necessity']!, _necessityMeta),
      );
    }
    if (data.containsKey('is_done')) {
      context.handle(
        _isDoneMeta,
        isDone.isAcceptableOrUnknown(data['is_done']!, _isDoneMeta),
      );
    }
    if (data.containsKey('note_id')) {
      context.handle(
        _noteIdMeta,
        noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta),
      );
    }
    if (data.containsKey('subtask_ids')) {
      context.handle(
        _subtaskIdsMeta,
        subtaskIds.isAcceptableOrUnknown(data['subtask_ids']!, _subtaskIdsMeta),
      );
    }
    if (data.containsKey('reminder_time')) {
      context.handle(
        _reminderTimeMeta,
        reminderTime.isAcceptableOrUnknown(
          data['reminder_time']!,
          _reminderTimeMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty'],
      )!,
      urgency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}urgency'],
      )!,
      necessity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}necessity'],
      )!,
      isDone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_done'],
      )!,
      noteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_id'],
      ),
      subtaskIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtask_ids'],
      )!,
      reminderTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_time'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class TaskRow extends DataClass implements Insertable<TaskRow> {
  final String id;
  final String title;
  final String type;
  final String? description;
  final String difficulty;
  final String urgency;
  final String necessity;
  final bool isDone;
  final String? noteId;
  final String subtaskIds;
  final String? reminderTime;
  final String? createdAt;
  final String? completedAt;
  const TaskRow({
    required this.id,
    required this.title,
    required this.type,
    this.description,
    required this.difficulty,
    required this.urgency,
    required this.necessity,
    required this.isDone,
    this.noteId,
    required this.subtaskIds,
    this.reminderTime,
    this.createdAt,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['difficulty'] = Variable<String>(difficulty);
    map['urgency'] = Variable<String>(urgency);
    map['necessity'] = Variable<String>(necessity);
    map['is_done'] = Variable<bool>(isDone);
    if (!nullToAbsent || noteId != null) {
      map['note_id'] = Variable<String>(noteId);
    }
    map['subtask_ids'] = Variable<String>(subtaskIds);
    if (!nullToAbsent || reminderTime != null) {
      map['reminder_time'] = Variable<String>(reminderTime);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<String>(completedAt);
    }
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      title: Value(title),
      type: Value(type),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      difficulty: Value(difficulty),
      urgency: Value(urgency),
      necessity: Value(necessity),
      isDone: Value(isDone),
      noteId: noteId == null && nullToAbsent
          ? const Value.absent()
          : Value(noteId),
      subtaskIds: Value(subtaskIds),
      reminderTime: reminderTime == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderTime),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory TaskRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      type: serializer.fromJson<String>(json['type']),
      description: serializer.fromJson<String?>(json['description']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
      urgency: serializer.fromJson<String>(json['urgency']),
      necessity: serializer.fromJson<String>(json['necessity']),
      isDone: serializer.fromJson<bool>(json['isDone']),
      noteId: serializer.fromJson<String?>(json['noteId']),
      subtaskIds: serializer.fromJson<String>(json['subtaskIds']),
      reminderTime: serializer.fromJson<String?>(json['reminderTime']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
      completedAt: serializer.fromJson<String?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'type': serializer.toJson<String>(type),
      'description': serializer.toJson<String?>(description),
      'difficulty': serializer.toJson<String>(difficulty),
      'urgency': serializer.toJson<String>(urgency),
      'necessity': serializer.toJson<String>(necessity),
      'isDone': serializer.toJson<bool>(isDone),
      'noteId': serializer.toJson<String?>(noteId),
      'subtaskIds': serializer.toJson<String>(subtaskIds),
      'reminderTime': serializer.toJson<String?>(reminderTime),
      'createdAt': serializer.toJson<String?>(createdAt),
      'completedAt': serializer.toJson<String?>(completedAt),
    };
  }

  TaskRow copyWith({
    String? id,
    String? title,
    String? type,
    Value<String?> description = const Value.absent(),
    String? difficulty,
    String? urgency,
    String? necessity,
    bool? isDone,
    Value<String?> noteId = const Value.absent(),
    String? subtaskIds,
    Value<String?> reminderTime = const Value.absent(),
    Value<String?> createdAt = const Value.absent(),
    Value<String?> completedAt = const Value.absent(),
  }) => TaskRow(
    id: id ?? this.id,
    title: title ?? this.title,
    type: type ?? this.type,
    description: description.present ? description.value : this.description,
    difficulty: difficulty ?? this.difficulty,
    urgency: urgency ?? this.urgency,
    necessity: necessity ?? this.necessity,
    isDone: isDone ?? this.isDone,
    noteId: noteId.present ? noteId.value : this.noteId,
    subtaskIds: subtaskIds ?? this.subtaskIds,
    reminderTime: reminderTime.present ? reminderTime.value : this.reminderTime,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  TaskRow copyWithCompanion(TasksCompanion data) {
    return TaskRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      type: data.type.present ? data.type.value : this.type,
      description: data.description.present
          ? data.description.value
          : this.description,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      urgency: data.urgency.present ? data.urgency.value : this.urgency,
      necessity: data.necessity.present ? data.necessity.value : this.necessity,
      isDone: data.isDone.present ? data.isDone.value : this.isDone,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      subtaskIds: data.subtaskIds.present
          ? data.subtaskIds.value
          : this.subtaskIds,
      reminderTime: data.reminderTime.present
          ? data.reminderTime.value
          : this.reminderTime,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('description: $description, ')
          ..write('difficulty: $difficulty, ')
          ..write('urgency: $urgency, ')
          ..write('necessity: $necessity, ')
          ..write('isDone: $isDone, ')
          ..write('noteId: $noteId, ')
          ..write('subtaskIds: $subtaskIds, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    type,
    description,
    difficulty,
    urgency,
    necessity,
    isDone,
    noteId,
    subtaskIds,
    reminderTime,
    createdAt,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.type == this.type &&
          other.description == this.description &&
          other.difficulty == this.difficulty &&
          other.urgency == this.urgency &&
          other.necessity == this.necessity &&
          other.isDone == this.isDone &&
          other.noteId == this.noteId &&
          other.subtaskIds == this.subtaskIds &&
          other.reminderTime == this.reminderTime &&
          other.createdAt == this.createdAt &&
          other.completedAt == this.completedAt);
}

class TasksCompanion extends UpdateCompanion<TaskRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> type;
  final Value<String?> description;
  final Value<String> difficulty;
  final Value<String> urgency;
  final Value<String> necessity;
  final Value<bool> isDone;
  final Value<String?> noteId;
  final Value<String> subtaskIds;
  final Value<String?> reminderTime;
  final Value<String?> createdAt;
  final Value<String?> completedAt;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.type = const Value.absent(),
    this.description = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.urgency = const Value.absent(),
    this.necessity = const Value.absent(),
    this.isDone = const Value.absent(),
    this.noteId = const Value.absent(),
    this.subtaskIds = const Value.absent(),
    this.reminderTime = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    required String title,
    this.type = const Value.absent(),
    this.description = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.urgency = const Value.absent(),
    this.necessity = const Value.absent(),
    this.isDone = const Value.absent(),
    this.noteId = const Value.absent(),
    this.subtaskIds = const Value.absent(),
    this.reminderTime = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title);
  static Insertable<TaskRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? type,
    Expression<String>? description,
    Expression<String>? difficulty,
    Expression<String>? urgency,
    Expression<String>? necessity,
    Expression<bool>? isDone,
    Expression<String>? noteId,
    Expression<String>? subtaskIds,
    Expression<String>? reminderTime,
    Expression<String>? createdAt,
    Expression<String>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (type != null) 'type': type,
      if (description != null) 'description': description,
      if (difficulty != null) 'difficulty': difficulty,
      if (urgency != null) 'urgency': urgency,
      if (necessity != null) 'necessity': necessity,
      if (isDone != null) 'is_done': isDone,
      if (noteId != null) 'note_id': noteId,
      if (subtaskIds != null) 'subtask_ids': subtaskIds,
      if (reminderTime != null) 'reminder_time': reminderTime,
      if (createdAt != null) 'created_at': createdAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? type,
    Value<String?>? description,
    Value<String>? difficulty,
    Value<String>? urgency,
    Value<String>? necessity,
    Value<bool>? isDone,
    Value<String?>? noteId,
    Value<String>? subtaskIds,
    Value<String?>? reminderTime,
    Value<String?>? createdAt,
    Value<String?>? completedAt,
    Value<int>? rowid,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      urgency: urgency ?? this.urgency,
      necessity: necessity ?? this.necessity,
      isDone: isDone ?? this.isDone,
      noteId: noteId ?? this.noteId,
      subtaskIds: subtaskIds ?? this.subtaskIds,
      reminderTime: reminderTime ?? this.reminderTime,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (urgency.present) {
      map['urgency'] = Variable<String>(urgency.value);
    }
    if (necessity.present) {
      map['necessity'] = Variable<String>(necessity.value);
    }
    if (isDone.present) {
      map['is_done'] = Variable<bool>(isDone.value);
    }
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (subtaskIds.present) {
      map['subtask_ids'] = Variable<String>(subtaskIds.value);
    }
    if (reminderTime.present) {
      map['reminder_time'] = Variable<String>(reminderTime.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<String>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('description: $description, ')
          ..write('difficulty: $difficulty, ')
          ..write('urgency: $urgency, ')
          ..write('necessity: $necessity, ')
          ..write('isDone: $isDone, ')
          ..write('noteId: $noteId, ')
          ..write('subtaskIds: $subtaskIds, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PetsTable extends Pets with TableInfo<$PetsTable, PetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('小云'),
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _expMeta = const VerificationMeta('exp');
  @override
  late final GeneratedColumn<int> exp = GeneratedColumn<int>(
    'exp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _stageMeta = const VerificationMeta('stage');
  @override
  late final GeneratedColumn<String> stage = GeneratedColumn<String>(
    'stage',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('droplet'),
  );
  static const VerificationMeta _happinessMeta = const VerificationMeta(
    'happiness',
  );
  @override
  late final GeneratedColumn<int> happiness = GeneratedColumn<int>(
    'happiness',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(80),
  );
  static const VerificationMeta _lastFedMeta = const VerificationMeta(
    'lastFed',
  );
  @override
  late final GeneratedColumn<int> lastFed = GeneratedColumn<int>(
    'last_fed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    level,
    exp,
    stage,
    happiness,
    lastFed,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pets';
  @override
  VerificationContext validateIntegrity(
    Insertable<PetRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    }
    if (data.containsKey('exp')) {
      context.handle(
        _expMeta,
        exp.isAcceptableOrUnknown(data['exp']!, _expMeta),
      );
    }
    if (data.containsKey('stage')) {
      context.handle(
        _stageMeta,
        stage.isAcceptableOrUnknown(data['stage']!, _stageMeta),
      );
    }
    if (data.containsKey('happiness')) {
      context.handle(
        _happinessMeta,
        happiness.isAcceptableOrUnknown(data['happiness']!, _happinessMeta),
      );
    }
    if (data.containsKey('last_fed')) {
      context.handle(
        _lastFedMeta,
        lastFed.isAcceptableOrUnknown(data['last_fed']!, _lastFedMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PetRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      exp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exp'],
      )!,
      stage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stage'],
      )!,
      happiness: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}happiness'],
      )!,
      lastFed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_fed'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $PetsTable createAlias(String alias) {
    return $PetsTable(attachedDatabase, alias);
  }
}

class PetRow extends DataClass implements Insertable<PetRow> {
  final int id;
  final String name;
  final int level;
  final int exp;
  final String stage;
  final int happiness;
  final int lastFed;
  final String? updatedAt;
  const PetRow({
    required this.id,
    required this.name,
    required this.level,
    required this.exp,
    required this.stage,
    required this.happiness,
    required this.lastFed,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['level'] = Variable<int>(level);
    map['exp'] = Variable<int>(exp);
    map['stage'] = Variable<String>(stage);
    map['happiness'] = Variable<int>(happiness);
    map['last_fed'] = Variable<int>(lastFed);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    return map;
  }

  PetsCompanion toCompanion(bool nullToAbsent) {
    return PetsCompanion(
      id: Value(id),
      name: Value(name),
      level: Value(level),
      exp: Value(exp),
      stage: Value(stage),
      happiness: Value(happiness),
      lastFed: Value(lastFed),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory PetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PetRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      level: serializer.fromJson<int>(json['level']),
      exp: serializer.fromJson<int>(json['exp']),
      stage: serializer.fromJson<String>(json['stage']),
      happiness: serializer.fromJson<int>(json['happiness']),
      lastFed: serializer.fromJson<int>(json['lastFed']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'level': serializer.toJson<int>(level),
      'exp': serializer.toJson<int>(exp),
      'stage': serializer.toJson<String>(stage),
      'happiness': serializer.toJson<int>(happiness),
      'lastFed': serializer.toJson<int>(lastFed),
      'updatedAt': serializer.toJson<String?>(updatedAt),
    };
  }

  PetRow copyWith({
    int? id,
    String? name,
    int? level,
    int? exp,
    String? stage,
    int? happiness,
    int? lastFed,
    Value<String?> updatedAt = const Value.absent(),
  }) => PetRow(
    id: id ?? this.id,
    name: name ?? this.name,
    level: level ?? this.level,
    exp: exp ?? this.exp,
    stage: stage ?? this.stage,
    happiness: happiness ?? this.happiness,
    lastFed: lastFed ?? this.lastFed,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  PetRow copyWithCompanion(PetsCompanion data) {
    return PetRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      level: data.level.present ? data.level.value : this.level,
      exp: data.exp.present ? data.exp.value : this.exp,
      stage: data.stage.present ? data.stage.value : this.stage,
      happiness: data.happiness.present ? data.happiness.value : this.happiness,
      lastFed: data.lastFed.present ? data.lastFed.value : this.lastFed,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PetRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('level: $level, ')
          ..write('exp: $exp, ')
          ..write('stage: $stage, ')
          ..write('happiness: $happiness, ')
          ..write('lastFed: $lastFed, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, level, exp, stage, happiness, lastFed, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PetRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.level == this.level &&
          other.exp == this.exp &&
          other.stage == this.stage &&
          other.happiness == this.happiness &&
          other.lastFed == this.lastFed &&
          other.updatedAt == this.updatedAt);
}

class PetsCompanion extends UpdateCompanion<PetRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> level;
  final Value<int> exp;
  final Value<String> stage;
  final Value<int> happiness;
  final Value<int> lastFed;
  final Value<String?> updatedAt;
  const PetsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.level = const Value.absent(),
    this.exp = const Value.absent(),
    this.stage = const Value.absent(),
    this.happiness = const Value.absent(),
    this.lastFed = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PetsCompanion.insert({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.level = const Value.absent(),
    this.exp = const Value.absent(),
    this.stage = const Value.absent(),
    this.happiness = const Value.absent(),
    this.lastFed = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  static Insertable<PetRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? level,
    Expression<int>? exp,
    Expression<String>? stage,
    Expression<int>? happiness,
    Expression<int>? lastFed,
    Expression<String>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (level != null) 'level': level,
      if (exp != null) 'exp': exp,
      if (stage != null) 'stage': stage,
      if (happiness != null) 'happiness': happiness,
      if (lastFed != null) 'last_fed': lastFed,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PetsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? level,
    Value<int>? exp,
    Value<String>? stage,
    Value<int>? happiness,
    Value<int>? lastFed,
    Value<String?>? updatedAt,
  }) {
    return PetsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      level: level ?? this.level,
      exp: exp ?? this.exp,
      stage: stage ?? this.stage,
      happiness: happiness ?? this.happiness,
      lastFed: lastFed ?? this.lastFed,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (exp.present) {
      map['exp'] = Variable<int>(exp.value);
    }
    if (stage.present) {
      map['stage'] = Variable<String>(stage.value);
    }
    if (happiness.present) {
      map['happiness'] = Variable<int>(happiness.value);
    }
    if (lastFed.present) {
      map['last_fed'] = Variable<int>(lastFed.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PetsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('level: $level, ')
          ..write('exp: $exp, ')
          ..write('stage: $stage, ')
          ..write('happiness: $happiness, ')
          ..write('lastFed: $lastFed, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $UserSettingsTableTable extends UserSettingsTable
    with TableInfo<$UserSettingsTableTable, UserSettingsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserSettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nicknameMeta = const VerificationMeta(
    'nickname',
  );
  @override
  late final GeneratedColumn<String> nickname = GeneratedColumn<String>(
    'nickname',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('小云同学'),
  );
  static const VerificationMeta _bioMeta = const VerificationMeta('bio');
  @override
  late final GeneratedColumn<String> bio = GeneratedColumn<String>(
    'bio',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('📚 知识探索者'),
  );
  static const VerificationMeta _avatarUrlMeta = const VerificationMeta(
    'avatarUrl',
  );
  @override
  late final GeneratedColumn<String> avatarUrl = GeneratedColumn<String>(
    'avatar_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _themeModeMeta = const VerificationMeta(
    'themeMode',
  );
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
    'theme_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('light'),
  );
  static const VerificationMeta _defaultMarkdownMeta = const VerificationMeta(
    'defaultMarkdown',
  );
  @override
  late final GeneratedColumn<bool> defaultMarkdown = GeneratedColumn<bool>(
    'default_markdown',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("default_markdown" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _reviewReminderHourMeta =
      const VerificationMeta('reviewReminderHour');
  @override
  late final GeneratedColumn<int> reviewReminderHour = GeneratedColumn<int>(
    'review_reminder_hour',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(20),
  );
  static const VerificationMeta _reviewReminderMinuteMeta =
      const VerificationMeta('reviewReminderMinute');
  @override
  late final GeneratedColumn<int> reviewReminderMinute = GeneratedColumn<int>(
    'review_reminder_minute',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dailyReviewLimitMeta = const VerificationMeta(
    'dailyReviewLimit',
  );
  @override
  late final GeneratedColumn<int> dailyReviewLimit = GeneratedColumn<int>(
    'daily_review_limit',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(20),
  );
  static const VerificationMeta _reviewFactorMeta = const VerificationMeta(
    'reviewFactor',
  );
  @override
  late final GeneratedColumn<double> reviewFactor = GeneratedColumn<double>(
    'review_factor',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(2.5),
  );
  static const VerificationMeta _heatmapStatModeMeta = const VerificationMeta(
    'heatmapStatMode',
  );
  @override
  late final GeneratedColumn<String> heatmapStatMode = GeneratedColumn<String>(
    'heatmap_stat_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('count'),
  );
  static const VerificationMeta _heatmapHighThresholdMeta =
      const VerificationMeta('heatmapHighThreshold');
  @override
  late final GeneratedColumn<int> heatmapHighThreshold = GeneratedColumn<int>(
    'heatmap_high_threshold',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _heatmapBurstThresholdMeta =
      const VerificationMeta('heatmapBurstThreshold');
  @override
  late final GeneratedColumn<int> heatmapBurstThreshold = GeneratedColumn<int>(
    'heatmap_burst_threshold',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(8),
  );
  static const VerificationMeta _heatmapWordHighThresholdMeta =
      const VerificationMeta('heatmapWordHighThreshold');
  @override
  late final GeneratedColumn<int> heatmapWordHighThreshold =
      GeneratedColumn<int>(
        'heatmap_word_high_threshold',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(300),
      );
  static const VerificationMeta _heatmapWordBurstThresholdMeta =
      const VerificationMeta('heatmapWordBurstThreshold');
  @override
  late final GeneratedColumn<int> heatmapWordBurstThreshold =
      GeneratedColumn<int>(
        'heatmap_word_burst_threshold',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(800),
      );
  static const VerificationMeta _heatmapColorSchemeMeta =
      const VerificationMeta('heatmapColorScheme');
  @override
  late final GeneratedColumn<String> heatmapColorScheme =
      GeneratedColumn<String>(
        'heatmap_color_scheme',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('emerald'),
      );
  static const VerificationMeta _heatmapColorLowMeta = const VerificationMeta(
    'heatmapColorLow',
  );
  @override
  late final GeneratedColumn<String> heatmapColorLow = GeneratedColumn<String>(
    'heatmap_color_low',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('#E8F5E9'),
  );
  static const VerificationMeta _heatmapColorMidMeta = const VerificationMeta(
    'heatmapColorMid',
  );
  @override
  late final GeneratedColumn<String> heatmapColorMid = GeneratedColumn<String>(
    'heatmap_color_mid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('#81C784'),
  );
  static const VerificationMeta _heatmapColorHighMeta = const VerificationMeta(
    'heatmapColorHigh',
  );
  @override
  late final GeneratedColumn<String> heatmapColorHigh = GeneratedColumn<String>(
    'heatmap_color_high',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('#FFD93D'),
  );
  static const VerificationMeta _heatmapColorBurstMeta = const VerificationMeta(
    'heatmapColorBurst',
  );
  @override
  late final GeneratedColumn<String> heatmapColorBurst =
      GeneratedColumn<String>(
        'heatmap_color_burst',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('#FF6B6B'),
      );
  static const VerificationMeta _showPetMeta = const VerificationMeta(
    'showPet',
  );
  @override
  late final GeneratedColumn<bool> showPet = GeneratedColumn<bool>(
    'show_pet',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_pet" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _petSkinMeta = const VerificationMeta(
    'petSkin',
  );
  @override
  late final GeneratedColumn<String> petSkin = GeneratedColumn<String>(
    'pet_skin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('default'),
  );
  static const VerificationMeta _petNameMeta = const VerificationMeta(
    'petName',
  );
  @override
  late final GeneratedColumn<String> petName = GeneratedColumn<String>(
    'pet_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('小云'),
  );
  static const VerificationMeta _petInFocusModeMeta = const VerificationMeta(
    'petInFocusMode',
  );
  @override
  late final GeneratedColumn<bool> petInFocusMode = GeneratedColumn<bool>(
    'pet_in_focus_mode',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pet_in_focus_mode" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _rawNoteRetentionDaysMeta =
      const VerificationMeta('rawNoteRetentionDays');
  @override
  late final GeneratedColumn<int> rawNoteRetentionDays = GeneratedColumn<int>(
    'raw_note_retention_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(15),
  );
  static const VerificationMeta _dailyWordTargetMeta = const VerificationMeta(
    'dailyWordTarget',
  );
  @override
  late final GeneratedColumn<int> dailyWordTarget = GeneratedColumn<int>(
    'daily_word_target',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _typewriterSoundMeta = const VerificationMeta(
    'typewriterSound',
  );
  @override
  late final GeneratedColumn<bool> typewriterSound = GeneratedColumn<bool>(
    'typewriter_sound',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("typewriter_sound" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _whiteNoiseVolumeMeta = const VerificationMeta(
    'whiteNoiseVolume',
  );
  @override
  late final GeneratedColumn<double> whiteNoiseVolume = GeneratedColumn<double>(
    'white_noise_volume',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.5),
  );
  static const VerificationMeta _restReminderOnMeta = const VerificationMeta(
    'restReminderOn',
  );
  @override
  late final GeneratedColumn<bool> restReminderOn = GeneratedColumn<bool>(
    'rest_reminder_on',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("rest_reminder_on" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _restReminderMinutesMeta =
      const VerificationMeta('restReminderMinutes');
  @override
  late final GeneratedColumn<int> restReminderMinutes = GeneratedColumn<int>(
    'rest_reminder_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(45),
  );
  static const VerificationMeta _customNoiseSourcesMeta =
      const VerificationMeta('customNoiseSources');
  @override
  late final GeneratedColumn<String> customNoiseSources =
      GeneratedColumn<String>(
        'custom_noise_sources',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _focusMinutesMeta = const VerificationMeta(
    'focusMinutes',
  );
  @override
  late final GeneratedColumn<int> focusMinutes = GeneratedColumn<int>(
    'focus_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(25),
  );
  static const VerificationMeta _readerFontSizeMeta = const VerificationMeta(
    'readerFontSize',
  );
  @override
  late final GeneratedColumn<double> readerFontSize = GeneratedColumn<double>(
    'reader_font_size',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(16.0),
  );
  static const VerificationMeta _readerLineHeightMeta = const VerificationMeta(
    'readerLineHeight',
  );
  @override
  late final GeneratedColumn<double> readerLineHeight = GeneratedColumn<double>(
    'reader_line_height',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.6),
  );
  static const VerificationMeta _readerFontFamilyMeta = const VerificationMeta(
    'readerFontFamily',
  );
  @override
  late final GeneratedColumn<String> readerFontFamily = GeneratedColumn<String>(
    'reader_font_family',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _readerThemeModeMeta = const VerificationMeta(
    'readerThemeMode',
  );
  @override
  late final GeneratedColumn<String> readerThemeMode = GeneratedColumn<String>(
    'reader_theme_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('light'),
  );
  static const VerificationMeta _readerCustomBgMeta = const VerificationMeta(
    'readerCustomBg',
  );
  @override
  late final GeneratedColumn<String> readerCustomBg = GeneratedColumn<String>(
    'reader_custom_bg',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _readerCustomTextMeta = const VerificationMeta(
    'readerCustomText',
  );
  @override
  late final GeneratedColumn<String> readerCustomText = GeneratedColumn<String>(
    'reader_custom_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _readerHighlightColorMeta =
      const VerificationMeta('readerHighlightColor');
  @override
  late final GeneratedColumn<String> readerHighlightColor =
      GeneratedColumn<String>(
        'reader_highlight_color',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('#FFD93D'),
      );
  static const VerificationMeta _readerDailyGoalMeta = const VerificationMeta(
    'readerDailyGoal',
  );
  @override
  late final GeneratedColumn<int> readerDailyGoal = GeneratedColumn<int>(
    'reader_daily_goal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _readerReminderEnabledMeta =
      const VerificationMeta('readerReminderEnabled');
  @override
  late final GeneratedColumn<bool> readerReminderEnabled =
      GeneratedColumn<bool>(
        'reader_reminder_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("reader_reminder_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _readerReminderIntervalMeta =
      const VerificationMeta('readerReminderInterval');
  @override
  late final GeneratedColumn<int> readerReminderInterval = GeneratedColumn<int>(
    'reader_reminder_interval',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(30),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nickname,
    bio,
    avatarUrl,
    themeMode,
    defaultMarkdown,
    reviewReminderHour,
    reviewReminderMinute,
    dailyReviewLimit,
    reviewFactor,
    heatmapStatMode,
    heatmapHighThreshold,
    heatmapBurstThreshold,
    heatmapWordHighThreshold,
    heatmapWordBurstThreshold,
    heatmapColorScheme,
    heatmapColorLow,
    heatmapColorMid,
    heatmapColorHigh,
    heatmapColorBurst,
    showPet,
    petSkin,
    petName,
    petInFocusMode,
    rawNoteRetentionDays,
    dailyWordTarget,
    typewriterSound,
    whiteNoiseVolume,
    restReminderOn,
    restReminderMinutes,
    customNoiseSources,
    focusMinutes,
    readerFontSize,
    readerLineHeight,
    readerFontFamily,
    readerThemeMode,
    readerCustomBg,
    readerCustomText,
    readerHighlightColor,
    readerDailyGoal,
    readerReminderEnabled,
    readerReminderInterval,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserSettingsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nickname')) {
      context.handle(
        _nicknameMeta,
        nickname.isAcceptableOrUnknown(data['nickname']!, _nicknameMeta),
      );
    }
    if (data.containsKey('bio')) {
      context.handle(
        _bioMeta,
        bio.isAcceptableOrUnknown(data['bio']!, _bioMeta),
      );
    }
    if (data.containsKey('avatar_url')) {
      context.handle(
        _avatarUrlMeta,
        avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta),
      );
    }
    if (data.containsKey('theme_mode')) {
      context.handle(
        _themeModeMeta,
        themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta),
      );
    }
    if (data.containsKey('default_markdown')) {
      context.handle(
        _defaultMarkdownMeta,
        defaultMarkdown.isAcceptableOrUnknown(
          data['default_markdown']!,
          _defaultMarkdownMeta,
        ),
      );
    }
    if (data.containsKey('review_reminder_hour')) {
      context.handle(
        _reviewReminderHourMeta,
        reviewReminderHour.isAcceptableOrUnknown(
          data['review_reminder_hour']!,
          _reviewReminderHourMeta,
        ),
      );
    }
    if (data.containsKey('review_reminder_minute')) {
      context.handle(
        _reviewReminderMinuteMeta,
        reviewReminderMinute.isAcceptableOrUnknown(
          data['review_reminder_minute']!,
          _reviewReminderMinuteMeta,
        ),
      );
    }
    if (data.containsKey('daily_review_limit')) {
      context.handle(
        _dailyReviewLimitMeta,
        dailyReviewLimit.isAcceptableOrUnknown(
          data['daily_review_limit']!,
          _dailyReviewLimitMeta,
        ),
      );
    }
    if (data.containsKey('review_factor')) {
      context.handle(
        _reviewFactorMeta,
        reviewFactor.isAcceptableOrUnknown(
          data['review_factor']!,
          _reviewFactorMeta,
        ),
      );
    }
    if (data.containsKey('heatmap_stat_mode')) {
      context.handle(
        _heatmapStatModeMeta,
        heatmapStatMode.isAcceptableOrUnknown(
          data['heatmap_stat_mode']!,
          _heatmapStatModeMeta,
        ),
      );
    }
    if (data.containsKey('heatmap_high_threshold')) {
      context.handle(
        _heatmapHighThresholdMeta,
        heatmapHighThreshold.isAcceptableOrUnknown(
          data['heatmap_high_threshold']!,
          _heatmapHighThresholdMeta,
        ),
      );
    }
    if (data.containsKey('heatmap_burst_threshold')) {
      context.handle(
        _heatmapBurstThresholdMeta,
        heatmapBurstThreshold.isAcceptableOrUnknown(
          data['heatmap_burst_threshold']!,
          _heatmapBurstThresholdMeta,
        ),
      );
    }
    if (data.containsKey('heatmap_word_high_threshold')) {
      context.handle(
        _heatmapWordHighThresholdMeta,
        heatmapWordHighThreshold.isAcceptableOrUnknown(
          data['heatmap_word_high_threshold']!,
          _heatmapWordHighThresholdMeta,
        ),
      );
    }
    if (data.containsKey('heatmap_word_burst_threshold')) {
      context.handle(
        _heatmapWordBurstThresholdMeta,
        heatmapWordBurstThreshold.isAcceptableOrUnknown(
          data['heatmap_word_burst_threshold']!,
          _heatmapWordBurstThresholdMeta,
        ),
      );
    }
    if (data.containsKey('heatmap_color_scheme')) {
      context.handle(
        _heatmapColorSchemeMeta,
        heatmapColorScheme.isAcceptableOrUnknown(
          data['heatmap_color_scheme']!,
          _heatmapColorSchemeMeta,
        ),
      );
    }
    if (data.containsKey('heatmap_color_low')) {
      context.handle(
        _heatmapColorLowMeta,
        heatmapColorLow.isAcceptableOrUnknown(
          data['heatmap_color_low']!,
          _heatmapColorLowMeta,
        ),
      );
    }
    if (data.containsKey('heatmap_color_mid')) {
      context.handle(
        _heatmapColorMidMeta,
        heatmapColorMid.isAcceptableOrUnknown(
          data['heatmap_color_mid']!,
          _heatmapColorMidMeta,
        ),
      );
    }
    if (data.containsKey('heatmap_color_high')) {
      context.handle(
        _heatmapColorHighMeta,
        heatmapColorHigh.isAcceptableOrUnknown(
          data['heatmap_color_high']!,
          _heatmapColorHighMeta,
        ),
      );
    }
    if (data.containsKey('heatmap_color_burst')) {
      context.handle(
        _heatmapColorBurstMeta,
        heatmapColorBurst.isAcceptableOrUnknown(
          data['heatmap_color_burst']!,
          _heatmapColorBurstMeta,
        ),
      );
    }
    if (data.containsKey('show_pet')) {
      context.handle(
        _showPetMeta,
        showPet.isAcceptableOrUnknown(data['show_pet']!, _showPetMeta),
      );
    }
    if (data.containsKey('pet_skin')) {
      context.handle(
        _petSkinMeta,
        petSkin.isAcceptableOrUnknown(data['pet_skin']!, _petSkinMeta),
      );
    }
    if (data.containsKey('pet_name')) {
      context.handle(
        _petNameMeta,
        petName.isAcceptableOrUnknown(data['pet_name']!, _petNameMeta),
      );
    }
    if (data.containsKey('pet_in_focus_mode')) {
      context.handle(
        _petInFocusModeMeta,
        petInFocusMode.isAcceptableOrUnknown(
          data['pet_in_focus_mode']!,
          _petInFocusModeMeta,
        ),
      );
    }
    if (data.containsKey('raw_note_retention_days')) {
      context.handle(
        _rawNoteRetentionDaysMeta,
        rawNoteRetentionDays.isAcceptableOrUnknown(
          data['raw_note_retention_days']!,
          _rawNoteRetentionDaysMeta,
        ),
      );
    }
    if (data.containsKey('daily_word_target')) {
      context.handle(
        _dailyWordTargetMeta,
        dailyWordTarget.isAcceptableOrUnknown(
          data['daily_word_target']!,
          _dailyWordTargetMeta,
        ),
      );
    }
    if (data.containsKey('typewriter_sound')) {
      context.handle(
        _typewriterSoundMeta,
        typewriterSound.isAcceptableOrUnknown(
          data['typewriter_sound']!,
          _typewriterSoundMeta,
        ),
      );
    }
    if (data.containsKey('white_noise_volume')) {
      context.handle(
        _whiteNoiseVolumeMeta,
        whiteNoiseVolume.isAcceptableOrUnknown(
          data['white_noise_volume']!,
          _whiteNoiseVolumeMeta,
        ),
      );
    }
    if (data.containsKey('rest_reminder_on')) {
      context.handle(
        _restReminderOnMeta,
        restReminderOn.isAcceptableOrUnknown(
          data['rest_reminder_on']!,
          _restReminderOnMeta,
        ),
      );
    }
    if (data.containsKey('rest_reminder_minutes')) {
      context.handle(
        _restReminderMinutesMeta,
        restReminderMinutes.isAcceptableOrUnknown(
          data['rest_reminder_minutes']!,
          _restReminderMinutesMeta,
        ),
      );
    }
    if (data.containsKey('custom_noise_sources')) {
      context.handle(
        _customNoiseSourcesMeta,
        customNoiseSources.isAcceptableOrUnknown(
          data['custom_noise_sources']!,
          _customNoiseSourcesMeta,
        ),
      );
    }
    if (data.containsKey('focus_minutes')) {
      context.handle(
        _focusMinutesMeta,
        focusMinutes.isAcceptableOrUnknown(
          data['focus_minutes']!,
          _focusMinutesMeta,
        ),
      );
    }
    if (data.containsKey('reader_font_size')) {
      context.handle(
        _readerFontSizeMeta,
        readerFontSize.isAcceptableOrUnknown(
          data['reader_font_size']!,
          _readerFontSizeMeta,
        ),
      );
    }
    if (data.containsKey('reader_line_height')) {
      context.handle(
        _readerLineHeightMeta,
        readerLineHeight.isAcceptableOrUnknown(
          data['reader_line_height']!,
          _readerLineHeightMeta,
        ),
      );
    }
    if (data.containsKey('reader_font_family')) {
      context.handle(
        _readerFontFamilyMeta,
        readerFontFamily.isAcceptableOrUnknown(
          data['reader_font_family']!,
          _readerFontFamilyMeta,
        ),
      );
    }
    if (data.containsKey('reader_theme_mode')) {
      context.handle(
        _readerThemeModeMeta,
        readerThemeMode.isAcceptableOrUnknown(
          data['reader_theme_mode']!,
          _readerThemeModeMeta,
        ),
      );
    }
    if (data.containsKey('reader_custom_bg')) {
      context.handle(
        _readerCustomBgMeta,
        readerCustomBg.isAcceptableOrUnknown(
          data['reader_custom_bg']!,
          _readerCustomBgMeta,
        ),
      );
    }
    if (data.containsKey('reader_custom_text')) {
      context.handle(
        _readerCustomTextMeta,
        readerCustomText.isAcceptableOrUnknown(
          data['reader_custom_text']!,
          _readerCustomTextMeta,
        ),
      );
    }
    if (data.containsKey('reader_highlight_color')) {
      context.handle(
        _readerHighlightColorMeta,
        readerHighlightColor.isAcceptableOrUnknown(
          data['reader_highlight_color']!,
          _readerHighlightColorMeta,
        ),
      );
    }
    if (data.containsKey('reader_daily_goal')) {
      context.handle(
        _readerDailyGoalMeta,
        readerDailyGoal.isAcceptableOrUnknown(
          data['reader_daily_goal']!,
          _readerDailyGoalMeta,
        ),
      );
    }
    if (data.containsKey('reader_reminder_enabled')) {
      context.handle(
        _readerReminderEnabledMeta,
        readerReminderEnabled.isAcceptableOrUnknown(
          data['reader_reminder_enabled']!,
          _readerReminderEnabledMeta,
        ),
      );
    }
    if (data.containsKey('reader_reminder_interval')) {
      context.handle(
        _readerReminderIntervalMeta,
        readerReminderInterval.isAcceptableOrUnknown(
          data['reader_reminder_interval']!,
          _readerReminderIntervalMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserSettingsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserSettingsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      nickname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nickname'],
      )!,
      bio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bio'],
      )!,
      avatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_url'],
      )!,
      themeMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_mode'],
      )!,
      defaultMarkdown: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}default_markdown'],
      )!,
      reviewReminderHour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}review_reminder_hour'],
      )!,
      reviewReminderMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}review_reminder_minute'],
      )!,
      dailyReviewLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_review_limit'],
      )!,
      reviewFactor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}review_factor'],
      )!,
      heatmapStatMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}heatmap_stat_mode'],
      )!,
      heatmapHighThreshold: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}heatmap_high_threshold'],
      )!,
      heatmapBurstThreshold: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}heatmap_burst_threshold'],
      )!,
      heatmapWordHighThreshold: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}heatmap_word_high_threshold'],
      )!,
      heatmapWordBurstThreshold: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}heatmap_word_burst_threshold'],
      )!,
      heatmapColorScheme: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}heatmap_color_scheme'],
      )!,
      heatmapColorLow: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}heatmap_color_low'],
      )!,
      heatmapColorMid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}heatmap_color_mid'],
      )!,
      heatmapColorHigh: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}heatmap_color_high'],
      )!,
      heatmapColorBurst: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}heatmap_color_burst'],
      )!,
      showPet: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_pet'],
      )!,
      petSkin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pet_skin'],
      )!,
      petName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pet_name'],
      )!,
      petInFocusMode: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pet_in_focus_mode'],
      )!,
      rawNoteRetentionDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}raw_note_retention_days'],
      )!,
      dailyWordTarget: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_word_target'],
      )!,
      typewriterSound: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}typewriter_sound'],
      )!,
      whiteNoiseVolume: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}white_noise_volume'],
      )!,
      restReminderOn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}rest_reminder_on'],
      )!,
      restReminderMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rest_reminder_minutes'],
      )!,
      customNoiseSources: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_noise_sources'],
      )!,
      focusMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}focus_minutes'],
      )!,
      readerFontSize: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}reader_font_size'],
      )!,
      readerLineHeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}reader_line_height'],
      )!,
      readerFontFamily: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reader_font_family'],
      )!,
      readerThemeMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reader_theme_mode'],
      )!,
      readerCustomBg: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reader_custom_bg'],
      )!,
      readerCustomText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reader_custom_text'],
      )!,
      readerHighlightColor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reader_highlight_color'],
      )!,
      readerDailyGoal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reader_daily_goal'],
      )!,
      readerReminderEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reader_reminder_enabled'],
      )!,
      readerReminderInterval: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reader_reminder_interval'],
      )!,
    );
  }

  @override
  $UserSettingsTableTable createAlias(String alias) {
    return $UserSettingsTableTable(attachedDatabase, alias);
  }
}

class UserSettingsTableData extends DataClass
    implements Insertable<UserSettingsTableData> {
  final int id;
  final String nickname;
  final String bio;
  final String avatarUrl;
  final String themeMode;
  final bool defaultMarkdown;
  final int reviewReminderHour;
  final int reviewReminderMinute;
  final int dailyReviewLimit;
  final double reviewFactor;
  final String heatmapStatMode;
  final int heatmapHighThreshold;
  final int heatmapBurstThreshold;
  final int heatmapWordHighThreshold;
  final int heatmapWordBurstThreshold;
  final String heatmapColorScheme;
  final String heatmapColorLow;
  final String heatmapColorMid;
  final String heatmapColorHigh;
  final String heatmapColorBurst;
  final bool showPet;
  final String petSkin;
  final String petName;
  final bool petInFocusMode;
  final int rawNoteRetentionDays;
  final int dailyWordTarget;
  final bool typewriterSound;
  final double whiteNoiseVolume;
  final bool restReminderOn;
  final int restReminderMinutes;
  final String customNoiseSources;
  final int focusMinutes;
  final double readerFontSize;
  final double readerLineHeight;
  final String readerFontFamily;
  final String readerThemeMode;
  final String readerCustomBg;
  final String readerCustomText;
  final String readerHighlightColor;
  final int readerDailyGoal;
  final bool readerReminderEnabled;
  final int readerReminderInterval;
  const UserSettingsTableData({
    required this.id,
    required this.nickname,
    required this.bio,
    required this.avatarUrl,
    required this.themeMode,
    required this.defaultMarkdown,
    required this.reviewReminderHour,
    required this.reviewReminderMinute,
    required this.dailyReviewLimit,
    required this.reviewFactor,
    required this.heatmapStatMode,
    required this.heatmapHighThreshold,
    required this.heatmapBurstThreshold,
    required this.heatmapWordHighThreshold,
    required this.heatmapWordBurstThreshold,
    required this.heatmapColorScheme,
    required this.heatmapColorLow,
    required this.heatmapColorMid,
    required this.heatmapColorHigh,
    required this.heatmapColorBurst,
    required this.showPet,
    required this.petSkin,
    required this.petName,
    required this.petInFocusMode,
    required this.rawNoteRetentionDays,
    required this.dailyWordTarget,
    required this.typewriterSound,
    required this.whiteNoiseVolume,
    required this.restReminderOn,
    required this.restReminderMinutes,
    required this.customNoiseSources,
    required this.focusMinutes,
    required this.readerFontSize,
    required this.readerLineHeight,
    required this.readerFontFamily,
    required this.readerThemeMode,
    required this.readerCustomBg,
    required this.readerCustomText,
    required this.readerHighlightColor,
    required this.readerDailyGoal,
    required this.readerReminderEnabled,
    required this.readerReminderInterval,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nickname'] = Variable<String>(nickname);
    map['bio'] = Variable<String>(bio);
    map['avatar_url'] = Variable<String>(avatarUrl);
    map['theme_mode'] = Variable<String>(themeMode);
    map['default_markdown'] = Variable<bool>(defaultMarkdown);
    map['review_reminder_hour'] = Variable<int>(reviewReminderHour);
    map['review_reminder_minute'] = Variable<int>(reviewReminderMinute);
    map['daily_review_limit'] = Variable<int>(dailyReviewLimit);
    map['review_factor'] = Variable<double>(reviewFactor);
    map['heatmap_stat_mode'] = Variable<String>(heatmapStatMode);
    map['heatmap_high_threshold'] = Variable<int>(heatmapHighThreshold);
    map['heatmap_burst_threshold'] = Variable<int>(heatmapBurstThreshold);
    map['heatmap_word_high_threshold'] = Variable<int>(
      heatmapWordHighThreshold,
    );
    map['heatmap_word_burst_threshold'] = Variable<int>(
      heatmapWordBurstThreshold,
    );
    map['heatmap_color_scheme'] = Variable<String>(heatmapColorScheme);
    map['heatmap_color_low'] = Variable<String>(heatmapColorLow);
    map['heatmap_color_mid'] = Variable<String>(heatmapColorMid);
    map['heatmap_color_high'] = Variable<String>(heatmapColorHigh);
    map['heatmap_color_burst'] = Variable<String>(heatmapColorBurst);
    map['show_pet'] = Variable<bool>(showPet);
    map['pet_skin'] = Variable<String>(petSkin);
    map['pet_name'] = Variable<String>(petName);
    map['pet_in_focus_mode'] = Variable<bool>(petInFocusMode);
    map['raw_note_retention_days'] = Variable<int>(rawNoteRetentionDays);
    map['daily_word_target'] = Variable<int>(dailyWordTarget);
    map['typewriter_sound'] = Variable<bool>(typewriterSound);
    map['white_noise_volume'] = Variable<double>(whiteNoiseVolume);
    map['rest_reminder_on'] = Variable<bool>(restReminderOn);
    map['rest_reminder_minutes'] = Variable<int>(restReminderMinutes);
    map['custom_noise_sources'] = Variable<String>(customNoiseSources);
    map['focus_minutes'] = Variable<int>(focusMinutes);
    map['reader_font_size'] = Variable<double>(readerFontSize);
    map['reader_line_height'] = Variable<double>(readerLineHeight);
    map['reader_font_family'] = Variable<String>(readerFontFamily);
    map['reader_theme_mode'] = Variable<String>(readerThemeMode);
    map['reader_custom_bg'] = Variable<String>(readerCustomBg);
    map['reader_custom_text'] = Variable<String>(readerCustomText);
    map['reader_highlight_color'] = Variable<String>(readerHighlightColor);
    map['reader_daily_goal'] = Variable<int>(readerDailyGoal);
    map['reader_reminder_enabled'] = Variable<bool>(readerReminderEnabled);
    map['reader_reminder_interval'] = Variable<int>(readerReminderInterval);
    return map;
  }

  UserSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return UserSettingsTableCompanion(
      id: Value(id),
      nickname: Value(nickname),
      bio: Value(bio),
      avatarUrl: Value(avatarUrl),
      themeMode: Value(themeMode),
      defaultMarkdown: Value(defaultMarkdown),
      reviewReminderHour: Value(reviewReminderHour),
      reviewReminderMinute: Value(reviewReminderMinute),
      dailyReviewLimit: Value(dailyReviewLimit),
      reviewFactor: Value(reviewFactor),
      heatmapStatMode: Value(heatmapStatMode),
      heatmapHighThreshold: Value(heatmapHighThreshold),
      heatmapBurstThreshold: Value(heatmapBurstThreshold),
      heatmapWordHighThreshold: Value(heatmapWordHighThreshold),
      heatmapWordBurstThreshold: Value(heatmapWordBurstThreshold),
      heatmapColorScheme: Value(heatmapColorScheme),
      heatmapColorLow: Value(heatmapColorLow),
      heatmapColorMid: Value(heatmapColorMid),
      heatmapColorHigh: Value(heatmapColorHigh),
      heatmapColorBurst: Value(heatmapColorBurst),
      showPet: Value(showPet),
      petSkin: Value(petSkin),
      petName: Value(petName),
      petInFocusMode: Value(petInFocusMode),
      rawNoteRetentionDays: Value(rawNoteRetentionDays),
      dailyWordTarget: Value(dailyWordTarget),
      typewriterSound: Value(typewriterSound),
      whiteNoiseVolume: Value(whiteNoiseVolume),
      restReminderOn: Value(restReminderOn),
      restReminderMinutes: Value(restReminderMinutes),
      customNoiseSources: Value(customNoiseSources),
      focusMinutes: Value(focusMinutes),
      readerFontSize: Value(readerFontSize),
      readerLineHeight: Value(readerLineHeight),
      readerFontFamily: Value(readerFontFamily),
      readerThemeMode: Value(readerThemeMode),
      readerCustomBg: Value(readerCustomBg),
      readerCustomText: Value(readerCustomText),
      readerHighlightColor: Value(readerHighlightColor),
      readerDailyGoal: Value(readerDailyGoal),
      readerReminderEnabled: Value(readerReminderEnabled),
      readerReminderInterval: Value(readerReminderInterval),
    );
  }

  factory UserSettingsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserSettingsTableData(
      id: serializer.fromJson<int>(json['id']),
      nickname: serializer.fromJson<String>(json['nickname']),
      bio: serializer.fromJson<String>(json['bio']),
      avatarUrl: serializer.fromJson<String>(json['avatarUrl']),
      themeMode: serializer.fromJson<String>(json['themeMode']),
      defaultMarkdown: serializer.fromJson<bool>(json['defaultMarkdown']),
      reviewReminderHour: serializer.fromJson<int>(json['reviewReminderHour']),
      reviewReminderMinute: serializer.fromJson<int>(
        json['reviewReminderMinute'],
      ),
      dailyReviewLimit: serializer.fromJson<int>(json['dailyReviewLimit']),
      reviewFactor: serializer.fromJson<double>(json['reviewFactor']),
      heatmapStatMode: serializer.fromJson<String>(json['heatmapStatMode']),
      heatmapHighThreshold: serializer.fromJson<int>(
        json['heatmapHighThreshold'],
      ),
      heatmapBurstThreshold: serializer.fromJson<int>(
        json['heatmapBurstThreshold'],
      ),
      heatmapWordHighThreshold: serializer.fromJson<int>(
        json['heatmapWordHighThreshold'],
      ),
      heatmapWordBurstThreshold: serializer.fromJson<int>(
        json['heatmapWordBurstThreshold'],
      ),
      heatmapColorScheme: serializer.fromJson<String>(
        json['heatmapColorScheme'],
      ),
      heatmapColorLow: serializer.fromJson<String>(json['heatmapColorLow']),
      heatmapColorMid: serializer.fromJson<String>(json['heatmapColorMid']),
      heatmapColorHigh: serializer.fromJson<String>(json['heatmapColorHigh']),
      heatmapColorBurst: serializer.fromJson<String>(json['heatmapColorBurst']),
      showPet: serializer.fromJson<bool>(json['showPet']),
      petSkin: serializer.fromJson<String>(json['petSkin']),
      petName: serializer.fromJson<String>(json['petName']),
      petInFocusMode: serializer.fromJson<bool>(json['petInFocusMode']),
      rawNoteRetentionDays: serializer.fromJson<int>(
        json['rawNoteRetentionDays'],
      ),
      dailyWordTarget: serializer.fromJson<int>(json['dailyWordTarget']),
      typewriterSound: serializer.fromJson<bool>(json['typewriterSound']),
      whiteNoiseVolume: serializer.fromJson<double>(json['whiteNoiseVolume']),
      restReminderOn: serializer.fromJson<bool>(json['restReminderOn']),
      restReminderMinutes: serializer.fromJson<int>(
        json['restReminderMinutes'],
      ),
      customNoiseSources: serializer.fromJson<String>(
        json['customNoiseSources'],
      ),
      focusMinutes: serializer.fromJson<int>(json['focusMinutes']),
      readerFontSize: serializer.fromJson<double>(json['readerFontSize']),
      readerLineHeight: serializer.fromJson<double>(json['readerLineHeight']),
      readerFontFamily: serializer.fromJson<String>(json['readerFontFamily']),
      readerThemeMode: serializer.fromJson<String>(json['readerThemeMode']),
      readerCustomBg: serializer.fromJson<String>(json['readerCustomBg']),
      readerCustomText: serializer.fromJson<String>(json['readerCustomText']),
      readerHighlightColor: serializer.fromJson<String>(
        json['readerHighlightColor'],
      ),
      readerDailyGoal: serializer.fromJson<int>(json['readerDailyGoal']),
      readerReminderEnabled: serializer.fromJson<bool>(
        json['readerReminderEnabled'],
      ),
      readerReminderInterval: serializer.fromJson<int>(
        json['readerReminderInterval'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nickname': serializer.toJson<String>(nickname),
      'bio': serializer.toJson<String>(bio),
      'avatarUrl': serializer.toJson<String>(avatarUrl),
      'themeMode': serializer.toJson<String>(themeMode),
      'defaultMarkdown': serializer.toJson<bool>(defaultMarkdown),
      'reviewReminderHour': serializer.toJson<int>(reviewReminderHour),
      'reviewReminderMinute': serializer.toJson<int>(reviewReminderMinute),
      'dailyReviewLimit': serializer.toJson<int>(dailyReviewLimit),
      'reviewFactor': serializer.toJson<double>(reviewFactor),
      'heatmapStatMode': serializer.toJson<String>(heatmapStatMode),
      'heatmapHighThreshold': serializer.toJson<int>(heatmapHighThreshold),
      'heatmapBurstThreshold': serializer.toJson<int>(heatmapBurstThreshold),
      'heatmapWordHighThreshold': serializer.toJson<int>(
        heatmapWordHighThreshold,
      ),
      'heatmapWordBurstThreshold': serializer.toJson<int>(
        heatmapWordBurstThreshold,
      ),
      'heatmapColorScheme': serializer.toJson<String>(heatmapColorScheme),
      'heatmapColorLow': serializer.toJson<String>(heatmapColorLow),
      'heatmapColorMid': serializer.toJson<String>(heatmapColorMid),
      'heatmapColorHigh': serializer.toJson<String>(heatmapColorHigh),
      'heatmapColorBurst': serializer.toJson<String>(heatmapColorBurst),
      'showPet': serializer.toJson<bool>(showPet),
      'petSkin': serializer.toJson<String>(petSkin),
      'petName': serializer.toJson<String>(petName),
      'petInFocusMode': serializer.toJson<bool>(petInFocusMode),
      'rawNoteRetentionDays': serializer.toJson<int>(rawNoteRetentionDays),
      'dailyWordTarget': serializer.toJson<int>(dailyWordTarget),
      'typewriterSound': serializer.toJson<bool>(typewriterSound),
      'whiteNoiseVolume': serializer.toJson<double>(whiteNoiseVolume),
      'restReminderOn': serializer.toJson<bool>(restReminderOn),
      'restReminderMinutes': serializer.toJson<int>(restReminderMinutes),
      'customNoiseSources': serializer.toJson<String>(customNoiseSources),
      'focusMinutes': serializer.toJson<int>(focusMinutes),
      'readerFontSize': serializer.toJson<double>(readerFontSize),
      'readerLineHeight': serializer.toJson<double>(readerLineHeight),
      'readerFontFamily': serializer.toJson<String>(readerFontFamily),
      'readerThemeMode': serializer.toJson<String>(readerThemeMode),
      'readerCustomBg': serializer.toJson<String>(readerCustomBg),
      'readerCustomText': serializer.toJson<String>(readerCustomText),
      'readerHighlightColor': serializer.toJson<String>(readerHighlightColor),
      'readerDailyGoal': serializer.toJson<int>(readerDailyGoal),
      'readerReminderEnabled': serializer.toJson<bool>(readerReminderEnabled),
      'readerReminderInterval': serializer.toJson<int>(readerReminderInterval),
    };
  }

  UserSettingsTableData copyWith({
    int? id,
    String? nickname,
    String? bio,
    String? avatarUrl,
    String? themeMode,
    bool? defaultMarkdown,
    int? reviewReminderHour,
    int? reviewReminderMinute,
    int? dailyReviewLimit,
    double? reviewFactor,
    String? heatmapStatMode,
    int? heatmapHighThreshold,
    int? heatmapBurstThreshold,
    int? heatmapWordHighThreshold,
    int? heatmapWordBurstThreshold,
    String? heatmapColorScheme,
    String? heatmapColorLow,
    String? heatmapColorMid,
    String? heatmapColorHigh,
    String? heatmapColorBurst,
    bool? showPet,
    String? petSkin,
    String? petName,
    bool? petInFocusMode,
    int? rawNoteRetentionDays,
    int? dailyWordTarget,
    bool? typewriterSound,
    double? whiteNoiseVolume,
    bool? restReminderOn,
    int? restReminderMinutes,
    String? customNoiseSources,
    int? focusMinutes,
    double? readerFontSize,
    double? readerLineHeight,
    String? readerFontFamily,
    String? readerThemeMode,
    String? readerCustomBg,
    String? readerCustomText,
    String? readerHighlightColor,
    int? readerDailyGoal,
    bool? readerReminderEnabled,
    int? readerReminderInterval,
  }) => UserSettingsTableData(
    id: id ?? this.id,
    nickname: nickname ?? this.nickname,
    bio: bio ?? this.bio,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    themeMode: themeMode ?? this.themeMode,
    defaultMarkdown: defaultMarkdown ?? this.defaultMarkdown,
    reviewReminderHour: reviewReminderHour ?? this.reviewReminderHour,
    reviewReminderMinute: reviewReminderMinute ?? this.reviewReminderMinute,
    dailyReviewLimit: dailyReviewLimit ?? this.dailyReviewLimit,
    reviewFactor: reviewFactor ?? this.reviewFactor,
    heatmapStatMode: heatmapStatMode ?? this.heatmapStatMode,
    heatmapHighThreshold: heatmapHighThreshold ?? this.heatmapHighThreshold,
    heatmapBurstThreshold: heatmapBurstThreshold ?? this.heatmapBurstThreshold,
    heatmapWordHighThreshold:
        heatmapWordHighThreshold ?? this.heatmapWordHighThreshold,
    heatmapWordBurstThreshold:
        heatmapWordBurstThreshold ?? this.heatmapWordBurstThreshold,
    heatmapColorScheme: heatmapColorScheme ?? this.heatmapColorScheme,
    heatmapColorLow: heatmapColorLow ?? this.heatmapColorLow,
    heatmapColorMid: heatmapColorMid ?? this.heatmapColorMid,
    heatmapColorHigh: heatmapColorHigh ?? this.heatmapColorHigh,
    heatmapColorBurst: heatmapColorBurst ?? this.heatmapColorBurst,
    showPet: showPet ?? this.showPet,
    petSkin: petSkin ?? this.petSkin,
    petName: petName ?? this.petName,
    petInFocusMode: petInFocusMode ?? this.petInFocusMode,
    rawNoteRetentionDays: rawNoteRetentionDays ?? this.rawNoteRetentionDays,
    dailyWordTarget: dailyWordTarget ?? this.dailyWordTarget,
    typewriterSound: typewriterSound ?? this.typewriterSound,
    whiteNoiseVolume: whiteNoiseVolume ?? this.whiteNoiseVolume,
    restReminderOn: restReminderOn ?? this.restReminderOn,
    restReminderMinutes: restReminderMinutes ?? this.restReminderMinutes,
    customNoiseSources: customNoiseSources ?? this.customNoiseSources,
    focusMinutes: focusMinutes ?? this.focusMinutes,
    readerFontSize: readerFontSize ?? this.readerFontSize,
    readerLineHeight: readerLineHeight ?? this.readerLineHeight,
    readerFontFamily: readerFontFamily ?? this.readerFontFamily,
    readerThemeMode: readerThemeMode ?? this.readerThemeMode,
    readerCustomBg: readerCustomBg ?? this.readerCustomBg,
    readerCustomText: readerCustomText ?? this.readerCustomText,
    readerHighlightColor: readerHighlightColor ?? this.readerHighlightColor,
    readerDailyGoal: readerDailyGoal ?? this.readerDailyGoal,
    readerReminderEnabled: readerReminderEnabled ?? this.readerReminderEnabled,
    readerReminderInterval:
        readerReminderInterval ?? this.readerReminderInterval,
  );
  UserSettingsTableData copyWithCompanion(UserSettingsTableCompanion data) {
    return UserSettingsTableData(
      id: data.id.present ? data.id.value : this.id,
      nickname: data.nickname.present ? data.nickname.value : this.nickname,
      bio: data.bio.present ? data.bio.value : this.bio,
      avatarUrl: data.avatarUrl.present ? data.avatarUrl.value : this.avatarUrl,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      defaultMarkdown: data.defaultMarkdown.present
          ? data.defaultMarkdown.value
          : this.defaultMarkdown,
      reviewReminderHour: data.reviewReminderHour.present
          ? data.reviewReminderHour.value
          : this.reviewReminderHour,
      reviewReminderMinute: data.reviewReminderMinute.present
          ? data.reviewReminderMinute.value
          : this.reviewReminderMinute,
      dailyReviewLimit: data.dailyReviewLimit.present
          ? data.dailyReviewLimit.value
          : this.dailyReviewLimit,
      reviewFactor: data.reviewFactor.present
          ? data.reviewFactor.value
          : this.reviewFactor,
      heatmapStatMode: data.heatmapStatMode.present
          ? data.heatmapStatMode.value
          : this.heatmapStatMode,
      heatmapHighThreshold: data.heatmapHighThreshold.present
          ? data.heatmapHighThreshold.value
          : this.heatmapHighThreshold,
      heatmapBurstThreshold: data.heatmapBurstThreshold.present
          ? data.heatmapBurstThreshold.value
          : this.heatmapBurstThreshold,
      heatmapWordHighThreshold: data.heatmapWordHighThreshold.present
          ? data.heatmapWordHighThreshold.value
          : this.heatmapWordHighThreshold,
      heatmapWordBurstThreshold: data.heatmapWordBurstThreshold.present
          ? data.heatmapWordBurstThreshold.value
          : this.heatmapWordBurstThreshold,
      heatmapColorScheme: data.heatmapColorScheme.present
          ? data.heatmapColorScheme.value
          : this.heatmapColorScheme,
      heatmapColorLow: data.heatmapColorLow.present
          ? data.heatmapColorLow.value
          : this.heatmapColorLow,
      heatmapColorMid: data.heatmapColorMid.present
          ? data.heatmapColorMid.value
          : this.heatmapColorMid,
      heatmapColorHigh: data.heatmapColorHigh.present
          ? data.heatmapColorHigh.value
          : this.heatmapColorHigh,
      heatmapColorBurst: data.heatmapColorBurst.present
          ? data.heatmapColorBurst.value
          : this.heatmapColorBurst,
      showPet: data.showPet.present ? data.showPet.value : this.showPet,
      petSkin: data.petSkin.present ? data.petSkin.value : this.petSkin,
      petName: data.petName.present ? data.petName.value : this.petName,
      petInFocusMode: data.petInFocusMode.present
          ? data.petInFocusMode.value
          : this.petInFocusMode,
      rawNoteRetentionDays: data.rawNoteRetentionDays.present
          ? data.rawNoteRetentionDays.value
          : this.rawNoteRetentionDays,
      dailyWordTarget: data.dailyWordTarget.present
          ? data.dailyWordTarget.value
          : this.dailyWordTarget,
      typewriterSound: data.typewriterSound.present
          ? data.typewriterSound.value
          : this.typewriterSound,
      whiteNoiseVolume: data.whiteNoiseVolume.present
          ? data.whiteNoiseVolume.value
          : this.whiteNoiseVolume,
      restReminderOn: data.restReminderOn.present
          ? data.restReminderOn.value
          : this.restReminderOn,
      restReminderMinutes: data.restReminderMinutes.present
          ? data.restReminderMinutes.value
          : this.restReminderMinutes,
      customNoiseSources: data.customNoiseSources.present
          ? data.customNoiseSources.value
          : this.customNoiseSources,
      focusMinutes: data.focusMinutes.present
          ? data.focusMinutes.value
          : this.focusMinutes,
      readerFontSize: data.readerFontSize.present
          ? data.readerFontSize.value
          : this.readerFontSize,
      readerLineHeight: data.readerLineHeight.present
          ? data.readerLineHeight.value
          : this.readerLineHeight,
      readerFontFamily: data.readerFontFamily.present
          ? data.readerFontFamily.value
          : this.readerFontFamily,
      readerThemeMode: data.readerThemeMode.present
          ? data.readerThemeMode.value
          : this.readerThemeMode,
      readerCustomBg: data.readerCustomBg.present
          ? data.readerCustomBg.value
          : this.readerCustomBg,
      readerCustomText: data.readerCustomText.present
          ? data.readerCustomText.value
          : this.readerCustomText,
      readerHighlightColor: data.readerHighlightColor.present
          ? data.readerHighlightColor.value
          : this.readerHighlightColor,
      readerDailyGoal: data.readerDailyGoal.present
          ? data.readerDailyGoal.value
          : this.readerDailyGoal,
      readerReminderEnabled: data.readerReminderEnabled.present
          ? data.readerReminderEnabled.value
          : this.readerReminderEnabled,
      readerReminderInterval: data.readerReminderInterval.present
          ? data.readerReminderInterval.value
          : this.readerReminderInterval,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserSettingsTableData(')
          ..write('id: $id, ')
          ..write('nickname: $nickname, ')
          ..write('bio: $bio, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('themeMode: $themeMode, ')
          ..write('defaultMarkdown: $defaultMarkdown, ')
          ..write('reviewReminderHour: $reviewReminderHour, ')
          ..write('reviewReminderMinute: $reviewReminderMinute, ')
          ..write('dailyReviewLimit: $dailyReviewLimit, ')
          ..write('reviewFactor: $reviewFactor, ')
          ..write('heatmapStatMode: $heatmapStatMode, ')
          ..write('heatmapHighThreshold: $heatmapHighThreshold, ')
          ..write('heatmapBurstThreshold: $heatmapBurstThreshold, ')
          ..write('heatmapWordHighThreshold: $heatmapWordHighThreshold, ')
          ..write('heatmapWordBurstThreshold: $heatmapWordBurstThreshold, ')
          ..write('heatmapColorScheme: $heatmapColorScheme, ')
          ..write('heatmapColorLow: $heatmapColorLow, ')
          ..write('heatmapColorMid: $heatmapColorMid, ')
          ..write('heatmapColorHigh: $heatmapColorHigh, ')
          ..write('heatmapColorBurst: $heatmapColorBurst, ')
          ..write('showPet: $showPet, ')
          ..write('petSkin: $petSkin, ')
          ..write('petName: $petName, ')
          ..write('petInFocusMode: $petInFocusMode, ')
          ..write('rawNoteRetentionDays: $rawNoteRetentionDays, ')
          ..write('dailyWordTarget: $dailyWordTarget, ')
          ..write('typewriterSound: $typewriterSound, ')
          ..write('whiteNoiseVolume: $whiteNoiseVolume, ')
          ..write('restReminderOn: $restReminderOn, ')
          ..write('restReminderMinutes: $restReminderMinutes, ')
          ..write('customNoiseSources: $customNoiseSources, ')
          ..write('focusMinutes: $focusMinutes, ')
          ..write('readerFontSize: $readerFontSize, ')
          ..write('readerLineHeight: $readerLineHeight, ')
          ..write('readerFontFamily: $readerFontFamily, ')
          ..write('readerThemeMode: $readerThemeMode, ')
          ..write('readerCustomBg: $readerCustomBg, ')
          ..write('readerCustomText: $readerCustomText, ')
          ..write('readerHighlightColor: $readerHighlightColor, ')
          ..write('readerDailyGoal: $readerDailyGoal, ')
          ..write('readerReminderEnabled: $readerReminderEnabled, ')
          ..write('readerReminderInterval: $readerReminderInterval')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    nickname,
    bio,
    avatarUrl,
    themeMode,
    defaultMarkdown,
    reviewReminderHour,
    reviewReminderMinute,
    dailyReviewLimit,
    reviewFactor,
    heatmapStatMode,
    heatmapHighThreshold,
    heatmapBurstThreshold,
    heatmapWordHighThreshold,
    heatmapWordBurstThreshold,
    heatmapColorScheme,
    heatmapColorLow,
    heatmapColorMid,
    heatmapColorHigh,
    heatmapColorBurst,
    showPet,
    petSkin,
    petName,
    petInFocusMode,
    rawNoteRetentionDays,
    dailyWordTarget,
    typewriterSound,
    whiteNoiseVolume,
    restReminderOn,
    restReminderMinutes,
    customNoiseSources,
    focusMinutes,
    readerFontSize,
    readerLineHeight,
    readerFontFamily,
    readerThemeMode,
    readerCustomBg,
    readerCustomText,
    readerHighlightColor,
    readerDailyGoal,
    readerReminderEnabled,
    readerReminderInterval,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserSettingsTableData &&
          other.id == this.id &&
          other.nickname == this.nickname &&
          other.bio == this.bio &&
          other.avatarUrl == this.avatarUrl &&
          other.themeMode == this.themeMode &&
          other.defaultMarkdown == this.defaultMarkdown &&
          other.reviewReminderHour == this.reviewReminderHour &&
          other.reviewReminderMinute == this.reviewReminderMinute &&
          other.dailyReviewLimit == this.dailyReviewLimit &&
          other.reviewFactor == this.reviewFactor &&
          other.heatmapStatMode == this.heatmapStatMode &&
          other.heatmapHighThreshold == this.heatmapHighThreshold &&
          other.heatmapBurstThreshold == this.heatmapBurstThreshold &&
          other.heatmapWordHighThreshold == this.heatmapWordHighThreshold &&
          other.heatmapWordBurstThreshold == this.heatmapWordBurstThreshold &&
          other.heatmapColorScheme == this.heatmapColorScheme &&
          other.heatmapColorLow == this.heatmapColorLow &&
          other.heatmapColorMid == this.heatmapColorMid &&
          other.heatmapColorHigh == this.heatmapColorHigh &&
          other.heatmapColorBurst == this.heatmapColorBurst &&
          other.showPet == this.showPet &&
          other.petSkin == this.petSkin &&
          other.petName == this.petName &&
          other.petInFocusMode == this.petInFocusMode &&
          other.rawNoteRetentionDays == this.rawNoteRetentionDays &&
          other.dailyWordTarget == this.dailyWordTarget &&
          other.typewriterSound == this.typewriterSound &&
          other.whiteNoiseVolume == this.whiteNoiseVolume &&
          other.restReminderOn == this.restReminderOn &&
          other.restReminderMinutes == this.restReminderMinutes &&
          other.customNoiseSources == this.customNoiseSources &&
          other.focusMinutes == this.focusMinutes &&
          other.readerFontSize == this.readerFontSize &&
          other.readerLineHeight == this.readerLineHeight &&
          other.readerFontFamily == this.readerFontFamily &&
          other.readerThemeMode == this.readerThemeMode &&
          other.readerCustomBg == this.readerCustomBg &&
          other.readerCustomText == this.readerCustomText &&
          other.readerHighlightColor == this.readerHighlightColor &&
          other.readerDailyGoal == this.readerDailyGoal &&
          other.readerReminderEnabled == this.readerReminderEnabled &&
          other.readerReminderInterval == this.readerReminderInterval);
}

class UserSettingsTableCompanion
    extends UpdateCompanion<UserSettingsTableData> {
  final Value<int> id;
  final Value<String> nickname;
  final Value<String> bio;
  final Value<String> avatarUrl;
  final Value<String> themeMode;
  final Value<bool> defaultMarkdown;
  final Value<int> reviewReminderHour;
  final Value<int> reviewReminderMinute;
  final Value<int> dailyReviewLimit;
  final Value<double> reviewFactor;
  final Value<String> heatmapStatMode;
  final Value<int> heatmapHighThreshold;
  final Value<int> heatmapBurstThreshold;
  final Value<int> heatmapWordHighThreshold;
  final Value<int> heatmapWordBurstThreshold;
  final Value<String> heatmapColorScheme;
  final Value<String> heatmapColorLow;
  final Value<String> heatmapColorMid;
  final Value<String> heatmapColorHigh;
  final Value<String> heatmapColorBurst;
  final Value<bool> showPet;
  final Value<String> petSkin;
  final Value<String> petName;
  final Value<bool> petInFocusMode;
  final Value<int> rawNoteRetentionDays;
  final Value<int> dailyWordTarget;
  final Value<bool> typewriterSound;
  final Value<double> whiteNoiseVolume;
  final Value<bool> restReminderOn;
  final Value<int> restReminderMinutes;
  final Value<String> customNoiseSources;
  final Value<int> focusMinutes;
  final Value<double> readerFontSize;
  final Value<double> readerLineHeight;
  final Value<String> readerFontFamily;
  final Value<String> readerThemeMode;
  final Value<String> readerCustomBg;
  final Value<String> readerCustomText;
  final Value<String> readerHighlightColor;
  final Value<int> readerDailyGoal;
  final Value<bool> readerReminderEnabled;
  final Value<int> readerReminderInterval;
  const UserSettingsTableCompanion({
    this.id = const Value.absent(),
    this.nickname = const Value.absent(),
    this.bio = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.defaultMarkdown = const Value.absent(),
    this.reviewReminderHour = const Value.absent(),
    this.reviewReminderMinute = const Value.absent(),
    this.dailyReviewLimit = const Value.absent(),
    this.reviewFactor = const Value.absent(),
    this.heatmapStatMode = const Value.absent(),
    this.heatmapHighThreshold = const Value.absent(),
    this.heatmapBurstThreshold = const Value.absent(),
    this.heatmapWordHighThreshold = const Value.absent(),
    this.heatmapWordBurstThreshold = const Value.absent(),
    this.heatmapColorScheme = const Value.absent(),
    this.heatmapColorLow = const Value.absent(),
    this.heatmapColorMid = const Value.absent(),
    this.heatmapColorHigh = const Value.absent(),
    this.heatmapColorBurst = const Value.absent(),
    this.showPet = const Value.absent(),
    this.petSkin = const Value.absent(),
    this.petName = const Value.absent(),
    this.petInFocusMode = const Value.absent(),
    this.rawNoteRetentionDays = const Value.absent(),
    this.dailyWordTarget = const Value.absent(),
    this.typewriterSound = const Value.absent(),
    this.whiteNoiseVolume = const Value.absent(),
    this.restReminderOn = const Value.absent(),
    this.restReminderMinutes = const Value.absent(),
    this.customNoiseSources = const Value.absent(),
    this.focusMinutes = const Value.absent(),
    this.readerFontSize = const Value.absent(),
    this.readerLineHeight = const Value.absent(),
    this.readerFontFamily = const Value.absent(),
    this.readerThemeMode = const Value.absent(),
    this.readerCustomBg = const Value.absent(),
    this.readerCustomText = const Value.absent(),
    this.readerHighlightColor = const Value.absent(),
    this.readerDailyGoal = const Value.absent(),
    this.readerReminderEnabled = const Value.absent(),
    this.readerReminderInterval = const Value.absent(),
  });
  UserSettingsTableCompanion.insert({
    this.id = const Value.absent(),
    this.nickname = const Value.absent(),
    this.bio = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.defaultMarkdown = const Value.absent(),
    this.reviewReminderHour = const Value.absent(),
    this.reviewReminderMinute = const Value.absent(),
    this.dailyReviewLimit = const Value.absent(),
    this.reviewFactor = const Value.absent(),
    this.heatmapStatMode = const Value.absent(),
    this.heatmapHighThreshold = const Value.absent(),
    this.heatmapBurstThreshold = const Value.absent(),
    this.heatmapWordHighThreshold = const Value.absent(),
    this.heatmapWordBurstThreshold = const Value.absent(),
    this.heatmapColorScheme = const Value.absent(),
    this.heatmapColorLow = const Value.absent(),
    this.heatmapColorMid = const Value.absent(),
    this.heatmapColorHigh = const Value.absent(),
    this.heatmapColorBurst = const Value.absent(),
    this.showPet = const Value.absent(),
    this.petSkin = const Value.absent(),
    this.petName = const Value.absent(),
    this.petInFocusMode = const Value.absent(),
    this.rawNoteRetentionDays = const Value.absent(),
    this.dailyWordTarget = const Value.absent(),
    this.typewriterSound = const Value.absent(),
    this.whiteNoiseVolume = const Value.absent(),
    this.restReminderOn = const Value.absent(),
    this.restReminderMinutes = const Value.absent(),
    this.customNoiseSources = const Value.absent(),
    this.focusMinutes = const Value.absent(),
    this.readerFontSize = const Value.absent(),
    this.readerLineHeight = const Value.absent(),
    this.readerFontFamily = const Value.absent(),
    this.readerThemeMode = const Value.absent(),
    this.readerCustomBg = const Value.absent(),
    this.readerCustomText = const Value.absent(),
    this.readerHighlightColor = const Value.absent(),
    this.readerDailyGoal = const Value.absent(),
    this.readerReminderEnabled = const Value.absent(),
    this.readerReminderInterval = const Value.absent(),
  });
  static Insertable<UserSettingsTableData> custom({
    Expression<int>? id,
    Expression<String>? nickname,
    Expression<String>? bio,
    Expression<String>? avatarUrl,
    Expression<String>? themeMode,
    Expression<bool>? defaultMarkdown,
    Expression<int>? reviewReminderHour,
    Expression<int>? reviewReminderMinute,
    Expression<int>? dailyReviewLimit,
    Expression<double>? reviewFactor,
    Expression<String>? heatmapStatMode,
    Expression<int>? heatmapHighThreshold,
    Expression<int>? heatmapBurstThreshold,
    Expression<int>? heatmapWordHighThreshold,
    Expression<int>? heatmapWordBurstThreshold,
    Expression<String>? heatmapColorScheme,
    Expression<String>? heatmapColorLow,
    Expression<String>? heatmapColorMid,
    Expression<String>? heatmapColorHigh,
    Expression<String>? heatmapColorBurst,
    Expression<bool>? showPet,
    Expression<String>? petSkin,
    Expression<String>? petName,
    Expression<bool>? petInFocusMode,
    Expression<int>? rawNoteRetentionDays,
    Expression<int>? dailyWordTarget,
    Expression<bool>? typewriterSound,
    Expression<double>? whiteNoiseVolume,
    Expression<bool>? restReminderOn,
    Expression<int>? restReminderMinutes,
    Expression<String>? customNoiseSources,
    Expression<int>? focusMinutes,
    Expression<double>? readerFontSize,
    Expression<double>? readerLineHeight,
    Expression<String>? readerFontFamily,
    Expression<String>? readerThemeMode,
    Expression<String>? readerCustomBg,
    Expression<String>? readerCustomText,
    Expression<String>? readerHighlightColor,
    Expression<int>? readerDailyGoal,
    Expression<bool>? readerReminderEnabled,
    Expression<int>? readerReminderInterval,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nickname != null) 'nickname': nickname,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (themeMode != null) 'theme_mode': themeMode,
      if (defaultMarkdown != null) 'default_markdown': defaultMarkdown,
      if (reviewReminderHour != null)
        'review_reminder_hour': reviewReminderHour,
      if (reviewReminderMinute != null)
        'review_reminder_minute': reviewReminderMinute,
      if (dailyReviewLimit != null) 'daily_review_limit': dailyReviewLimit,
      if (reviewFactor != null) 'review_factor': reviewFactor,
      if (heatmapStatMode != null) 'heatmap_stat_mode': heatmapStatMode,
      if (heatmapHighThreshold != null)
        'heatmap_high_threshold': heatmapHighThreshold,
      if (heatmapBurstThreshold != null)
        'heatmap_burst_threshold': heatmapBurstThreshold,
      if (heatmapWordHighThreshold != null)
        'heatmap_word_high_threshold': heatmapWordHighThreshold,
      if (heatmapWordBurstThreshold != null)
        'heatmap_word_burst_threshold': heatmapWordBurstThreshold,
      if (heatmapColorScheme != null)
        'heatmap_color_scheme': heatmapColorScheme,
      if (heatmapColorLow != null) 'heatmap_color_low': heatmapColorLow,
      if (heatmapColorMid != null) 'heatmap_color_mid': heatmapColorMid,
      if (heatmapColorHigh != null) 'heatmap_color_high': heatmapColorHigh,
      if (heatmapColorBurst != null) 'heatmap_color_burst': heatmapColorBurst,
      if (showPet != null) 'show_pet': showPet,
      if (petSkin != null) 'pet_skin': petSkin,
      if (petName != null) 'pet_name': petName,
      if (petInFocusMode != null) 'pet_in_focus_mode': petInFocusMode,
      if (rawNoteRetentionDays != null)
        'raw_note_retention_days': rawNoteRetentionDays,
      if (dailyWordTarget != null) 'daily_word_target': dailyWordTarget,
      if (typewriterSound != null) 'typewriter_sound': typewriterSound,
      if (whiteNoiseVolume != null) 'white_noise_volume': whiteNoiseVolume,
      if (restReminderOn != null) 'rest_reminder_on': restReminderOn,
      if (restReminderMinutes != null)
        'rest_reminder_minutes': restReminderMinutes,
      if (customNoiseSources != null)
        'custom_noise_sources': customNoiseSources,
      if (focusMinutes != null) 'focus_minutes': focusMinutes,
      if (readerFontSize != null) 'reader_font_size': readerFontSize,
      if (readerLineHeight != null) 'reader_line_height': readerLineHeight,
      if (readerFontFamily != null) 'reader_font_family': readerFontFamily,
      if (readerThemeMode != null) 'reader_theme_mode': readerThemeMode,
      if (readerCustomBg != null) 'reader_custom_bg': readerCustomBg,
      if (readerCustomText != null) 'reader_custom_text': readerCustomText,
      if (readerHighlightColor != null)
        'reader_highlight_color': readerHighlightColor,
      if (readerDailyGoal != null) 'reader_daily_goal': readerDailyGoal,
      if (readerReminderEnabled != null)
        'reader_reminder_enabled': readerReminderEnabled,
      if (readerReminderInterval != null)
        'reader_reminder_interval': readerReminderInterval,
    });
  }

  UserSettingsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? nickname,
    Value<String>? bio,
    Value<String>? avatarUrl,
    Value<String>? themeMode,
    Value<bool>? defaultMarkdown,
    Value<int>? reviewReminderHour,
    Value<int>? reviewReminderMinute,
    Value<int>? dailyReviewLimit,
    Value<double>? reviewFactor,
    Value<String>? heatmapStatMode,
    Value<int>? heatmapHighThreshold,
    Value<int>? heatmapBurstThreshold,
    Value<int>? heatmapWordHighThreshold,
    Value<int>? heatmapWordBurstThreshold,
    Value<String>? heatmapColorScheme,
    Value<String>? heatmapColorLow,
    Value<String>? heatmapColorMid,
    Value<String>? heatmapColorHigh,
    Value<String>? heatmapColorBurst,
    Value<bool>? showPet,
    Value<String>? petSkin,
    Value<String>? petName,
    Value<bool>? petInFocusMode,
    Value<int>? rawNoteRetentionDays,
    Value<int>? dailyWordTarget,
    Value<bool>? typewriterSound,
    Value<double>? whiteNoiseVolume,
    Value<bool>? restReminderOn,
    Value<int>? restReminderMinutes,
    Value<String>? customNoiseSources,
    Value<int>? focusMinutes,
    Value<double>? readerFontSize,
    Value<double>? readerLineHeight,
    Value<String>? readerFontFamily,
    Value<String>? readerThemeMode,
    Value<String>? readerCustomBg,
    Value<String>? readerCustomText,
    Value<String>? readerHighlightColor,
    Value<int>? readerDailyGoal,
    Value<bool>? readerReminderEnabled,
    Value<int>? readerReminderInterval,
  }) {
    return UserSettingsTableCompanion(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      themeMode: themeMode ?? this.themeMode,
      defaultMarkdown: defaultMarkdown ?? this.defaultMarkdown,
      reviewReminderHour: reviewReminderHour ?? this.reviewReminderHour,
      reviewReminderMinute: reviewReminderMinute ?? this.reviewReminderMinute,
      dailyReviewLimit: dailyReviewLimit ?? this.dailyReviewLimit,
      reviewFactor: reviewFactor ?? this.reviewFactor,
      heatmapStatMode: heatmapStatMode ?? this.heatmapStatMode,
      heatmapHighThreshold: heatmapHighThreshold ?? this.heatmapHighThreshold,
      heatmapBurstThreshold:
          heatmapBurstThreshold ?? this.heatmapBurstThreshold,
      heatmapWordHighThreshold:
          heatmapWordHighThreshold ?? this.heatmapWordHighThreshold,
      heatmapWordBurstThreshold:
          heatmapWordBurstThreshold ?? this.heatmapWordBurstThreshold,
      heatmapColorScheme: heatmapColorScheme ?? this.heatmapColorScheme,
      heatmapColorLow: heatmapColorLow ?? this.heatmapColorLow,
      heatmapColorMid: heatmapColorMid ?? this.heatmapColorMid,
      heatmapColorHigh: heatmapColorHigh ?? this.heatmapColorHigh,
      heatmapColorBurst: heatmapColorBurst ?? this.heatmapColorBurst,
      showPet: showPet ?? this.showPet,
      petSkin: petSkin ?? this.petSkin,
      petName: petName ?? this.petName,
      petInFocusMode: petInFocusMode ?? this.petInFocusMode,
      rawNoteRetentionDays: rawNoteRetentionDays ?? this.rawNoteRetentionDays,
      dailyWordTarget: dailyWordTarget ?? this.dailyWordTarget,
      typewriterSound: typewriterSound ?? this.typewriterSound,
      whiteNoiseVolume: whiteNoiseVolume ?? this.whiteNoiseVolume,
      restReminderOn: restReminderOn ?? this.restReminderOn,
      restReminderMinutes: restReminderMinutes ?? this.restReminderMinutes,
      customNoiseSources: customNoiseSources ?? this.customNoiseSources,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      readerFontSize: readerFontSize ?? this.readerFontSize,
      readerLineHeight: readerLineHeight ?? this.readerLineHeight,
      readerFontFamily: readerFontFamily ?? this.readerFontFamily,
      readerThemeMode: readerThemeMode ?? this.readerThemeMode,
      readerCustomBg: readerCustomBg ?? this.readerCustomBg,
      readerCustomText: readerCustomText ?? this.readerCustomText,
      readerHighlightColor: readerHighlightColor ?? this.readerHighlightColor,
      readerDailyGoal: readerDailyGoal ?? this.readerDailyGoal,
      readerReminderEnabled:
          readerReminderEnabled ?? this.readerReminderEnabled,
      readerReminderInterval:
          readerReminderInterval ?? this.readerReminderInterval,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nickname.present) {
      map['nickname'] = Variable<String>(nickname.value);
    }
    if (bio.present) {
      map['bio'] = Variable<String>(bio.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String>(avatarUrl.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (defaultMarkdown.present) {
      map['default_markdown'] = Variable<bool>(defaultMarkdown.value);
    }
    if (reviewReminderHour.present) {
      map['review_reminder_hour'] = Variable<int>(reviewReminderHour.value);
    }
    if (reviewReminderMinute.present) {
      map['review_reminder_minute'] = Variable<int>(reviewReminderMinute.value);
    }
    if (dailyReviewLimit.present) {
      map['daily_review_limit'] = Variable<int>(dailyReviewLimit.value);
    }
    if (reviewFactor.present) {
      map['review_factor'] = Variable<double>(reviewFactor.value);
    }
    if (heatmapStatMode.present) {
      map['heatmap_stat_mode'] = Variable<String>(heatmapStatMode.value);
    }
    if (heatmapHighThreshold.present) {
      map['heatmap_high_threshold'] = Variable<int>(heatmapHighThreshold.value);
    }
    if (heatmapBurstThreshold.present) {
      map['heatmap_burst_threshold'] = Variable<int>(
        heatmapBurstThreshold.value,
      );
    }
    if (heatmapWordHighThreshold.present) {
      map['heatmap_word_high_threshold'] = Variable<int>(
        heatmapWordHighThreshold.value,
      );
    }
    if (heatmapWordBurstThreshold.present) {
      map['heatmap_word_burst_threshold'] = Variable<int>(
        heatmapWordBurstThreshold.value,
      );
    }
    if (heatmapColorScheme.present) {
      map['heatmap_color_scheme'] = Variable<String>(heatmapColorScheme.value);
    }
    if (heatmapColorLow.present) {
      map['heatmap_color_low'] = Variable<String>(heatmapColorLow.value);
    }
    if (heatmapColorMid.present) {
      map['heatmap_color_mid'] = Variable<String>(heatmapColorMid.value);
    }
    if (heatmapColorHigh.present) {
      map['heatmap_color_high'] = Variable<String>(heatmapColorHigh.value);
    }
    if (heatmapColorBurst.present) {
      map['heatmap_color_burst'] = Variable<String>(heatmapColorBurst.value);
    }
    if (showPet.present) {
      map['show_pet'] = Variable<bool>(showPet.value);
    }
    if (petSkin.present) {
      map['pet_skin'] = Variable<String>(petSkin.value);
    }
    if (petName.present) {
      map['pet_name'] = Variable<String>(petName.value);
    }
    if (petInFocusMode.present) {
      map['pet_in_focus_mode'] = Variable<bool>(petInFocusMode.value);
    }
    if (rawNoteRetentionDays.present) {
      map['raw_note_retention_days'] = Variable<int>(
        rawNoteRetentionDays.value,
      );
    }
    if (dailyWordTarget.present) {
      map['daily_word_target'] = Variable<int>(dailyWordTarget.value);
    }
    if (typewriterSound.present) {
      map['typewriter_sound'] = Variable<bool>(typewriterSound.value);
    }
    if (whiteNoiseVolume.present) {
      map['white_noise_volume'] = Variable<double>(whiteNoiseVolume.value);
    }
    if (restReminderOn.present) {
      map['rest_reminder_on'] = Variable<bool>(restReminderOn.value);
    }
    if (restReminderMinutes.present) {
      map['rest_reminder_minutes'] = Variable<int>(restReminderMinutes.value);
    }
    if (customNoiseSources.present) {
      map['custom_noise_sources'] = Variable<String>(customNoiseSources.value);
    }
    if (focusMinutes.present) {
      map['focus_minutes'] = Variable<int>(focusMinutes.value);
    }
    if (readerFontSize.present) {
      map['reader_font_size'] = Variable<double>(readerFontSize.value);
    }
    if (readerLineHeight.present) {
      map['reader_line_height'] = Variable<double>(readerLineHeight.value);
    }
    if (readerFontFamily.present) {
      map['reader_font_family'] = Variable<String>(readerFontFamily.value);
    }
    if (readerThemeMode.present) {
      map['reader_theme_mode'] = Variable<String>(readerThemeMode.value);
    }
    if (readerCustomBg.present) {
      map['reader_custom_bg'] = Variable<String>(readerCustomBg.value);
    }
    if (readerCustomText.present) {
      map['reader_custom_text'] = Variable<String>(readerCustomText.value);
    }
    if (readerHighlightColor.present) {
      map['reader_highlight_color'] = Variable<String>(
        readerHighlightColor.value,
      );
    }
    if (readerDailyGoal.present) {
      map['reader_daily_goal'] = Variable<int>(readerDailyGoal.value);
    }
    if (readerReminderEnabled.present) {
      map['reader_reminder_enabled'] = Variable<bool>(
        readerReminderEnabled.value,
      );
    }
    if (readerReminderInterval.present) {
      map['reader_reminder_interval'] = Variable<int>(
        readerReminderInterval.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserSettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('nickname: $nickname, ')
          ..write('bio: $bio, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('themeMode: $themeMode, ')
          ..write('defaultMarkdown: $defaultMarkdown, ')
          ..write('reviewReminderHour: $reviewReminderHour, ')
          ..write('reviewReminderMinute: $reviewReminderMinute, ')
          ..write('dailyReviewLimit: $dailyReviewLimit, ')
          ..write('reviewFactor: $reviewFactor, ')
          ..write('heatmapStatMode: $heatmapStatMode, ')
          ..write('heatmapHighThreshold: $heatmapHighThreshold, ')
          ..write('heatmapBurstThreshold: $heatmapBurstThreshold, ')
          ..write('heatmapWordHighThreshold: $heatmapWordHighThreshold, ')
          ..write('heatmapWordBurstThreshold: $heatmapWordBurstThreshold, ')
          ..write('heatmapColorScheme: $heatmapColorScheme, ')
          ..write('heatmapColorLow: $heatmapColorLow, ')
          ..write('heatmapColorMid: $heatmapColorMid, ')
          ..write('heatmapColorHigh: $heatmapColorHigh, ')
          ..write('heatmapColorBurst: $heatmapColorBurst, ')
          ..write('showPet: $showPet, ')
          ..write('petSkin: $petSkin, ')
          ..write('petName: $petName, ')
          ..write('petInFocusMode: $petInFocusMode, ')
          ..write('rawNoteRetentionDays: $rawNoteRetentionDays, ')
          ..write('dailyWordTarget: $dailyWordTarget, ')
          ..write('typewriterSound: $typewriterSound, ')
          ..write('whiteNoiseVolume: $whiteNoiseVolume, ')
          ..write('restReminderOn: $restReminderOn, ')
          ..write('restReminderMinutes: $restReminderMinutes, ')
          ..write('customNoiseSources: $customNoiseSources, ')
          ..write('focusMinutes: $focusMinutes, ')
          ..write('readerFontSize: $readerFontSize, ')
          ..write('readerLineHeight: $readerLineHeight, ')
          ..write('readerFontFamily: $readerFontFamily, ')
          ..write('readerThemeMode: $readerThemeMode, ')
          ..write('readerCustomBg: $readerCustomBg, ')
          ..write('readerCustomText: $readerCustomText, ')
          ..write('readerHighlightColor: $readerHighlightColor, ')
          ..write('readerDailyGoal: $readerDailyGoal, ')
          ..write('readerReminderEnabled: $readerReminderEnabled, ')
          ..write('readerReminderInterval: $readerReminderInterval')
          ..write(')'))
        .toString();
  }
}

class $IsbnCacheTable extends IsbnCache
    with TableInfo<$IsbnCacheTable, IsbnCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IsbnCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _isbnMeta = const VerificationMeta('isbn');
  @override
  late final GeneratedColumn<String> isbn = GeneratedColumn<String>(
    'isbn',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverUrlMeta = const VerificationMeta(
    'coverUrl',
  );
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
    'cover_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    isbn,
    title,
    author,
    coverUrl,
    source,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'isbn_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<IsbnCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('isbn')) {
      context.handle(
        _isbnMeta,
        isbn.isAcceptableOrUnknown(data['isbn']!, _isbnMeta),
      );
    } else if (isInserting) {
      context.missing(_isbnMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('cover_url')) {
      context.handle(
        _coverUrlMeta,
        coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {isbn};
  @override
  IsbnCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IsbnCacheData(
      isbn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}isbn'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      ),
      coverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_url'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $IsbnCacheTable createAlias(String alias) {
    return $IsbnCacheTable(attachedDatabase, alias);
  }
}

class IsbnCacheData extends DataClass implements Insertable<IsbnCacheData> {
  final String isbn;
  final String? title;
  final String? author;
  final String? coverUrl;
  final String? source;
  final String? updatedAt;
  const IsbnCacheData({
    required this.isbn,
    this.title,
    this.author,
    this.coverUrl,
    this.source,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['isbn'] = Variable<String>(isbn);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = Variable<String>(coverUrl);
    }
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    return map;
  }

  IsbnCacheCompanion toCompanion(bool nullToAbsent) {
    return IsbnCacheCompanion(
      isbn: Value(isbn),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      author: author == null && nullToAbsent
          ? const Value.absent()
          : Value(author),
      coverUrl: coverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUrl),
      source: source == null && nullToAbsent
          ? const Value.absent()
          : Value(source),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory IsbnCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IsbnCacheData(
      isbn: serializer.fromJson<String>(json['isbn']),
      title: serializer.fromJson<String?>(json['title']),
      author: serializer.fromJson<String?>(json['author']),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
      source: serializer.fromJson<String?>(json['source']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'isbn': serializer.toJson<String>(isbn),
      'title': serializer.toJson<String?>(title),
      'author': serializer.toJson<String?>(author),
      'coverUrl': serializer.toJson<String?>(coverUrl),
      'source': serializer.toJson<String?>(source),
      'updatedAt': serializer.toJson<String?>(updatedAt),
    };
  }

  IsbnCacheData copyWith({
    String? isbn,
    Value<String?> title = const Value.absent(),
    Value<String?> author = const Value.absent(),
    Value<String?> coverUrl = const Value.absent(),
    Value<String?> source = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
  }) => IsbnCacheData(
    isbn: isbn ?? this.isbn,
    title: title.present ? title.value : this.title,
    author: author.present ? author.value : this.author,
    coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
    source: source.present ? source.value : this.source,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  IsbnCacheData copyWithCompanion(IsbnCacheCompanion data) {
    return IsbnCacheData(
      isbn: data.isbn.present ? data.isbn.value : this.isbn,
      title: data.title.present ? data.title.value : this.title,
      author: data.author.present ? data.author.value : this.author,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      source: data.source.present ? data.source.value : this.source,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IsbnCacheData(')
          ..write('isbn: $isbn, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('source: $source, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(isbn, title, author, coverUrl, source, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IsbnCacheData &&
          other.isbn == this.isbn &&
          other.title == this.title &&
          other.author == this.author &&
          other.coverUrl == this.coverUrl &&
          other.source == this.source &&
          other.updatedAt == this.updatedAt);
}

class IsbnCacheCompanion extends UpdateCompanion<IsbnCacheData> {
  final Value<String> isbn;
  final Value<String?> title;
  final Value<String?> author;
  final Value<String?> coverUrl;
  final Value<String?> source;
  final Value<String?> updatedAt;
  final Value<int> rowid;
  const IsbnCacheCompanion({
    this.isbn = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.source = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IsbnCacheCompanion.insert({
    required String isbn,
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.source = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : isbn = Value(isbn);
  static Insertable<IsbnCacheData> custom({
    Expression<String>? isbn,
    Expression<String>? title,
    Expression<String>? author,
    Expression<String>? coverUrl,
    Expression<String>? source,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (isbn != null) 'isbn': isbn,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (source != null) 'source': source,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IsbnCacheCompanion copyWith({
    Value<String>? isbn,
    Value<String?>? title,
    Value<String?>? author,
    Value<String?>? coverUrl,
    Value<String?>? source,
    Value<String?>? updatedAt,
    Value<int>? rowid,
  }) {
    return IsbnCacheCompanion(
      isbn: isbn ?? this.isbn,
      title: title ?? this.title,
      author: author ?? this.author,
      coverUrl: coverUrl ?? this.coverUrl,
      source: source ?? this.source,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (isbn.present) {
      map['isbn'] = Variable<String>(isbn.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IsbnCacheCompanion(')
          ..write('isbn: $isbn, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('source: $source, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PdfDrawingsTable extends PdfDrawings
    with TableInfo<$PdfDrawingsTable, PdfDrawingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PdfDrawingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
    'page',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pointsMeta = const VerificationMeta('points');
  @override
  late final GeneratedColumn<String> points = GeneratedColumn<String>(
    'points',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bookId,
    page,
    points,
    color,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pdf_drawings';
  @override
  VerificationContext validateIntegrity(
    Insertable<PdfDrawingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    }
    if (data.containsKey('page')) {
      context.handle(
        _pageMeta,
        page.isAcceptableOrUnknown(data['page']!, _pageMeta),
      );
    }
    if (data.containsKey('points')) {
      context.handle(
        _pointsMeta,
        points.isAcceptableOrUnknown(data['points']!, _pointsMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PdfDrawingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PdfDrawingRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      ),
      page: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page'],
      ),
      points: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}points'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $PdfDrawingsTable createAlias(String alias) {
    return $PdfDrawingsTable(attachedDatabase, alias);
  }
}

class PdfDrawingRow extends DataClass implements Insertable<PdfDrawingRow> {
  final String id;
  final String? bookId;
  final int? page;
  final String? points;
  final String? color;
  final String? createdAt;
  const PdfDrawingRow({
    required this.id,
    this.bookId,
    this.page,
    this.points,
    this.color,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || bookId != null) {
      map['book_id'] = Variable<String>(bookId);
    }
    if (!nullToAbsent || page != null) {
      map['page'] = Variable<int>(page);
    }
    if (!nullToAbsent || points != null) {
      map['points'] = Variable<String>(points);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    return map;
  }

  PdfDrawingsCompanion toCompanion(bool nullToAbsent) {
    return PdfDrawingsCompanion(
      id: Value(id),
      bookId: bookId == null && nullToAbsent
          ? const Value.absent()
          : Value(bookId),
      page: page == null && nullToAbsent ? const Value.absent() : Value(page),
      points: points == null && nullToAbsent
          ? const Value.absent()
          : Value(points),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory PdfDrawingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PdfDrawingRow(
      id: serializer.fromJson<String>(json['id']),
      bookId: serializer.fromJson<String?>(json['bookId']),
      page: serializer.fromJson<int?>(json['page']),
      points: serializer.fromJson<String?>(json['points']),
      color: serializer.fromJson<String?>(json['color']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bookId': serializer.toJson<String?>(bookId),
      'page': serializer.toJson<int?>(page),
      'points': serializer.toJson<String?>(points),
      'color': serializer.toJson<String?>(color),
      'createdAt': serializer.toJson<String?>(createdAt),
    };
  }

  PdfDrawingRow copyWith({
    String? id,
    Value<String?> bookId = const Value.absent(),
    Value<int?> page = const Value.absent(),
    Value<String?> points = const Value.absent(),
    Value<String?> color = const Value.absent(),
    Value<String?> createdAt = const Value.absent(),
  }) => PdfDrawingRow(
    id: id ?? this.id,
    bookId: bookId.present ? bookId.value : this.bookId,
    page: page.present ? page.value : this.page,
    points: points.present ? points.value : this.points,
    color: color.present ? color.value : this.color,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  PdfDrawingRow copyWithCompanion(PdfDrawingsCompanion data) {
    return PdfDrawingRow(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      page: data.page.present ? data.page.value : this.page,
      points: data.points.present ? data.points.value : this.points,
      color: data.color.present ? data.color.value : this.color,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PdfDrawingRow(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('page: $page, ')
          ..write('points: $points, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, bookId, page, points, color, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PdfDrawingRow &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.page == this.page &&
          other.points == this.points &&
          other.color == this.color &&
          other.createdAt == this.createdAt);
}

class PdfDrawingsCompanion extends UpdateCompanion<PdfDrawingRow> {
  final Value<String> id;
  final Value<String?> bookId;
  final Value<int?> page;
  final Value<String?> points;
  final Value<String?> color;
  final Value<String?> createdAt;
  final Value<int> rowid;
  const PdfDrawingsCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.page = const Value.absent(),
    this.points = const Value.absent(),
    this.color = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PdfDrawingsCompanion.insert({
    required String id,
    this.bookId = const Value.absent(),
    this.page = const Value.absent(),
    this.points = const Value.absent(),
    this.color = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<PdfDrawingRow> custom({
    Expression<String>? id,
    Expression<String>? bookId,
    Expression<int>? page,
    Expression<String>? points,
    Expression<String>? color,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (page != null) 'page': page,
      if (points != null) 'points': points,
      if (color != null) 'color': color,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PdfDrawingsCompanion copyWith({
    Value<String>? id,
    Value<String?>? bookId,
    Value<int?>? page,
    Value<String?>? points,
    Value<String?>? color,
    Value<String?>? createdAt,
    Value<int>? rowid,
  }) {
    return PdfDrawingsCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      page: page ?? this.page,
      points: points ?? this.points,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (points.present) {
      map['points'] = Variable<String>(points.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PdfDrawingsCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('page: $page, ')
          ..write('points: $points, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BoardViewsTable extends BoardViews
    with TableInfo<$BoardViewsTable, BoardView> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BoardViewsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    type,
    ownerId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'board_views';
  @override
  VerificationContext validateIntegrity(
    Insertable<BoardView> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BoardView map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BoardView(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      ),
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $BoardViewsTable createAlias(String alias) {
    return $BoardViewsTable(attachedDatabase, alias);
  }
}

class BoardView extends DataClass implements Insertable<BoardView> {
  final String id;
  final String? name;
  final String? type;
  final String? ownerId;
  final String? createdAt;
  final String? updatedAt;
  const BoardView({
    required this.id,
    this.name,
    this.type,
    this.ownerId,
    this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || type != null) {
      map['type'] = Variable<String>(type);
    }
    if (!nullToAbsent || ownerId != null) {
      map['owner_id'] = Variable<String>(ownerId);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    return map;
  }

  BoardViewsCompanion toCompanion(bool nullToAbsent) {
    return BoardViewsCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      type: type == null && nullToAbsent ? const Value.absent() : Value(type),
      ownerId: ownerId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerId),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory BoardView.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BoardView(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      type: serializer.fromJson<String?>(json['type']),
      ownerId: serializer.fromJson<String?>(json['ownerId']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String?>(name),
      'type': serializer.toJson<String?>(type),
      'ownerId': serializer.toJson<String?>(ownerId),
      'createdAt': serializer.toJson<String?>(createdAt),
      'updatedAt': serializer.toJson<String?>(updatedAt),
    };
  }

  BoardView copyWith({
    String? id,
    Value<String?> name = const Value.absent(),
    Value<String?> type = const Value.absent(),
    Value<String?> ownerId = const Value.absent(),
    Value<String?> createdAt = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
  }) => BoardView(
    id: id ?? this.id,
    name: name.present ? name.value : this.name,
    type: type.present ? type.value : this.type,
    ownerId: ownerId.present ? ownerId.value : this.ownerId,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  BoardView copyWithCompanion(BoardViewsCompanion data) {
    return BoardView(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BoardView(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('ownerId: $ownerId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, type, ownerId, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BoardView &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.ownerId == this.ownerId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BoardViewsCompanion extends UpdateCompanion<BoardView> {
  final Value<String> id;
  final Value<String?> name;
  final Value<String?> type;
  final Value<String?> ownerId;
  final Value<String?> createdAt;
  final Value<String?> updatedAt;
  final Value<int> rowid;
  const BoardViewsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BoardViewsCompanion.insert({
    required String id,
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<BoardView> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? ownerId,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (ownerId != null) 'owner_id': ownerId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BoardViewsCompanion copyWith({
    Value<String>? id,
    Value<String?>? name,
    Value<String?>? type,
    Value<String?>? ownerId,
    Value<String?>? createdAt,
    Value<String?>? updatedAt,
    Value<int>? rowid,
  }) {
    return BoardViewsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BoardViewsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('ownerId: $ownerId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BoardNodesTable extends BoardNodes
    with TableInfo<$BoardNodesTable, BoardNode> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BoardNodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _viewIdMeta = const VerificationMeta('viewId');
  @override
  late final GeneratedColumn<String> viewId = GeneratedColumn<String>(
    'view_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
    'card_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('card'),
  );
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
    'note_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _xMeta = const VerificationMeta('x');
  @override
  late final GeneratedColumn<double> x = GeneratedColumn<double>(
    'x',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yMeta = const VerificationMeta('y');
  @override
  late final GeneratedColumn<double> y = GeneratedColumn<double>(
    'y',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _zIndexMeta = const VerificationMeta('zIndex');
  @override
  late final GeneratedColumn<int> zIndex = GeneratedColumn<int>(
    'z_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    viewId,
    cardId,
    type,
    noteId,
    x,
    y,
    zIndex,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'board_nodes';
  @override
  VerificationContext validateIntegrity(
    Insertable<BoardNode> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('view_id')) {
      context.handle(
        _viewIdMeta,
        viewId.isAcceptableOrUnknown(data['view_id']!, _viewIdMeta),
      );
    }
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('note_id')) {
      context.handle(
        _noteIdMeta,
        noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta),
      );
    }
    if (data.containsKey('x')) {
      context.handle(_xMeta, x.isAcceptableOrUnknown(data['x']!, _xMeta));
    }
    if (data.containsKey('y')) {
      context.handle(_yMeta, y.isAcceptableOrUnknown(data['y']!, _yMeta));
    }
    if (data.containsKey('z_index')) {
      context.handle(
        _zIndexMeta,
        zIndex.isAcceptableOrUnknown(data['z_index']!, _zIndexMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BoardNode map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BoardNode(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      viewId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}view_id'],
      ),
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_id'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      noteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_id'],
      ),
      x: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}x'],
      ),
      y: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}y'],
      ),
      zIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}z_index'],
      ),
    );
  }

  @override
  $BoardNodesTable createAlias(String alias) {
    return $BoardNodesTable(attachedDatabase, alias);
  }
}

class BoardNode extends DataClass implements Insertable<BoardNode> {
  final String id;
  final String? viewId;
  final String? cardId;
  final String type;
  final String? noteId;
  final double? x;
  final double? y;
  final int? zIndex;
  const BoardNode({
    required this.id,
    this.viewId,
    this.cardId,
    required this.type,
    this.noteId,
    this.x,
    this.y,
    this.zIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || viewId != null) {
      map['view_id'] = Variable<String>(viewId);
    }
    if (!nullToAbsent || cardId != null) {
      map['card_id'] = Variable<String>(cardId);
    }
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || noteId != null) {
      map['note_id'] = Variable<String>(noteId);
    }
    if (!nullToAbsent || x != null) {
      map['x'] = Variable<double>(x);
    }
    if (!nullToAbsent || y != null) {
      map['y'] = Variable<double>(y);
    }
    if (!nullToAbsent || zIndex != null) {
      map['z_index'] = Variable<int>(zIndex);
    }
    return map;
  }

  BoardNodesCompanion toCompanion(bool nullToAbsent) {
    return BoardNodesCompanion(
      id: Value(id),
      viewId: viewId == null && nullToAbsent
          ? const Value.absent()
          : Value(viewId),
      cardId: cardId == null && nullToAbsent
          ? const Value.absent()
          : Value(cardId),
      type: Value(type),
      noteId: noteId == null && nullToAbsent
          ? const Value.absent()
          : Value(noteId),
      x: x == null && nullToAbsent ? const Value.absent() : Value(x),
      y: y == null && nullToAbsent ? const Value.absent() : Value(y),
      zIndex: zIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(zIndex),
    );
  }

  factory BoardNode.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BoardNode(
      id: serializer.fromJson<String>(json['id']),
      viewId: serializer.fromJson<String?>(json['viewId']),
      cardId: serializer.fromJson<String?>(json['cardId']),
      type: serializer.fromJson<String>(json['type']),
      noteId: serializer.fromJson<String?>(json['noteId']),
      x: serializer.fromJson<double?>(json['x']),
      y: serializer.fromJson<double?>(json['y']),
      zIndex: serializer.fromJson<int?>(json['zIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'viewId': serializer.toJson<String?>(viewId),
      'cardId': serializer.toJson<String?>(cardId),
      'type': serializer.toJson<String>(type),
      'noteId': serializer.toJson<String?>(noteId),
      'x': serializer.toJson<double?>(x),
      'y': serializer.toJson<double?>(y),
      'zIndex': serializer.toJson<int?>(zIndex),
    };
  }

  BoardNode copyWith({
    String? id,
    Value<String?> viewId = const Value.absent(),
    Value<String?> cardId = const Value.absent(),
    String? type,
    Value<String?> noteId = const Value.absent(),
    Value<double?> x = const Value.absent(),
    Value<double?> y = const Value.absent(),
    Value<int?> zIndex = const Value.absent(),
  }) => BoardNode(
    id: id ?? this.id,
    viewId: viewId.present ? viewId.value : this.viewId,
    cardId: cardId.present ? cardId.value : this.cardId,
    type: type ?? this.type,
    noteId: noteId.present ? noteId.value : this.noteId,
    x: x.present ? x.value : this.x,
    y: y.present ? y.value : this.y,
    zIndex: zIndex.present ? zIndex.value : this.zIndex,
  );
  BoardNode copyWithCompanion(BoardNodesCompanion data) {
    return BoardNode(
      id: data.id.present ? data.id.value : this.id,
      viewId: data.viewId.present ? data.viewId.value : this.viewId,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      type: data.type.present ? data.type.value : this.type,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      x: data.x.present ? data.x.value : this.x,
      y: data.y.present ? data.y.value : this.y,
      zIndex: data.zIndex.present ? data.zIndex.value : this.zIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BoardNode(')
          ..write('id: $id, ')
          ..write('viewId: $viewId, ')
          ..write('cardId: $cardId, ')
          ..write('type: $type, ')
          ..write('noteId: $noteId, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('zIndex: $zIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, viewId, cardId, type, noteId, x, y, zIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BoardNode &&
          other.id == this.id &&
          other.viewId == this.viewId &&
          other.cardId == this.cardId &&
          other.type == this.type &&
          other.noteId == this.noteId &&
          other.x == this.x &&
          other.y == this.y &&
          other.zIndex == this.zIndex);
}

class BoardNodesCompanion extends UpdateCompanion<BoardNode> {
  final Value<String> id;
  final Value<String?> viewId;
  final Value<String?> cardId;
  final Value<String> type;
  final Value<String?> noteId;
  final Value<double?> x;
  final Value<double?> y;
  final Value<int?> zIndex;
  final Value<int> rowid;
  const BoardNodesCompanion({
    this.id = const Value.absent(),
    this.viewId = const Value.absent(),
    this.cardId = const Value.absent(),
    this.type = const Value.absent(),
    this.noteId = const Value.absent(),
    this.x = const Value.absent(),
    this.y = const Value.absent(),
    this.zIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BoardNodesCompanion.insert({
    required String id,
    this.viewId = const Value.absent(),
    this.cardId = const Value.absent(),
    this.type = const Value.absent(),
    this.noteId = const Value.absent(),
    this.x = const Value.absent(),
    this.y = const Value.absent(),
    this.zIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<BoardNode> custom({
    Expression<String>? id,
    Expression<String>? viewId,
    Expression<String>? cardId,
    Expression<String>? type,
    Expression<String>? noteId,
    Expression<double>? x,
    Expression<double>? y,
    Expression<int>? zIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (viewId != null) 'view_id': viewId,
      if (cardId != null) 'card_id': cardId,
      if (type != null) 'type': type,
      if (noteId != null) 'note_id': noteId,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (zIndex != null) 'z_index': zIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BoardNodesCompanion copyWith({
    Value<String>? id,
    Value<String?>? viewId,
    Value<String?>? cardId,
    Value<String>? type,
    Value<String?>? noteId,
    Value<double?>? x,
    Value<double?>? y,
    Value<int?>? zIndex,
    Value<int>? rowid,
  }) {
    return BoardNodesCompanion(
      id: id ?? this.id,
      viewId: viewId ?? this.viewId,
      cardId: cardId ?? this.cardId,
      type: type ?? this.type,
      noteId: noteId ?? this.noteId,
      x: x ?? this.x,
      y: y ?? this.y,
      zIndex: zIndex ?? this.zIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (viewId.present) {
      map['view_id'] = Variable<String>(viewId.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (x.present) {
      map['x'] = Variable<double>(x.value);
    }
    if (y.present) {
      map['y'] = Variable<double>(y.value);
    }
    if (zIndex.present) {
      map['z_index'] = Variable<int>(zIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BoardNodesCompanion(')
          ..write('id: $id, ')
          ..write('viewId: $viewId, ')
          ..write('cardId: $cardId, ')
          ..write('type: $type, ')
          ..write('noteId: $noteId, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('zIndex: $zIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BoardEdgesTable extends BoardEdges
    with TableInfo<$BoardEdgesTable, BoardEdge> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BoardEdgesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _viewIdMeta = const VerificationMeta('viewId');
  @override
  late final GeneratedColumn<String> viewId = GeneratedColumn<String>(
    'view_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceNodeIdMeta = const VerificationMeta(
    'sourceNodeId',
  );
  @override
  late final GeneratedColumn<String> sourceNodeId = GeneratedColumn<String>(
    'source_node_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetNodeIdMeta = const VerificationMeta(
    'targetNodeId',
  );
  @override
  late final GeneratedColumn<String> targetNodeId = GeneratedColumn<String>(
    'target_node_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    viewId,
    sourceNodeId,
    targetNodeId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'board_edges';
  @override
  VerificationContext validateIntegrity(
    Insertable<BoardEdge> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('view_id')) {
      context.handle(
        _viewIdMeta,
        viewId.isAcceptableOrUnknown(data['view_id']!, _viewIdMeta),
      );
    }
    if (data.containsKey('source_node_id')) {
      context.handle(
        _sourceNodeIdMeta,
        sourceNodeId.isAcceptableOrUnknown(
          data['source_node_id']!,
          _sourceNodeIdMeta,
        ),
      );
    }
    if (data.containsKey('target_node_id')) {
      context.handle(
        _targetNodeIdMeta,
        targetNodeId.isAcceptableOrUnknown(
          data['target_node_id']!,
          _targetNodeIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BoardEdge map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BoardEdge(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      viewId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}view_id'],
      ),
      sourceNodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_node_id'],
      ),
      targetNodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_node_id'],
      ),
    );
  }

  @override
  $BoardEdgesTable createAlias(String alias) {
    return $BoardEdgesTable(attachedDatabase, alias);
  }
}

class BoardEdge extends DataClass implements Insertable<BoardEdge> {
  final String id;
  final String? viewId;
  final String? sourceNodeId;
  final String? targetNodeId;
  const BoardEdge({
    required this.id,
    this.viewId,
    this.sourceNodeId,
    this.targetNodeId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || viewId != null) {
      map['view_id'] = Variable<String>(viewId);
    }
    if (!nullToAbsent || sourceNodeId != null) {
      map['source_node_id'] = Variable<String>(sourceNodeId);
    }
    if (!nullToAbsent || targetNodeId != null) {
      map['target_node_id'] = Variable<String>(targetNodeId);
    }
    return map;
  }

  BoardEdgesCompanion toCompanion(bool nullToAbsent) {
    return BoardEdgesCompanion(
      id: Value(id),
      viewId: viewId == null && nullToAbsent
          ? const Value.absent()
          : Value(viewId),
      sourceNodeId: sourceNodeId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceNodeId),
      targetNodeId: targetNodeId == null && nullToAbsent
          ? const Value.absent()
          : Value(targetNodeId),
    );
  }

  factory BoardEdge.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BoardEdge(
      id: serializer.fromJson<String>(json['id']),
      viewId: serializer.fromJson<String?>(json['viewId']),
      sourceNodeId: serializer.fromJson<String?>(json['sourceNodeId']),
      targetNodeId: serializer.fromJson<String?>(json['targetNodeId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'viewId': serializer.toJson<String?>(viewId),
      'sourceNodeId': serializer.toJson<String?>(sourceNodeId),
      'targetNodeId': serializer.toJson<String?>(targetNodeId),
    };
  }

  BoardEdge copyWith({
    String? id,
    Value<String?> viewId = const Value.absent(),
    Value<String?> sourceNodeId = const Value.absent(),
    Value<String?> targetNodeId = const Value.absent(),
  }) => BoardEdge(
    id: id ?? this.id,
    viewId: viewId.present ? viewId.value : this.viewId,
    sourceNodeId: sourceNodeId.present ? sourceNodeId.value : this.sourceNodeId,
    targetNodeId: targetNodeId.present ? targetNodeId.value : this.targetNodeId,
  );
  BoardEdge copyWithCompanion(BoardEdgesCompanion data) {
    return BoardEdge(
      id: data.id.present ? data.id.value : this.id,
      viewId: data.viewId.present ? data.viewId.value : this.viewId,
      sourceNodeId: data.sourceNodeId.present
          ? data.sourceNodeId.value
          : this.sourceNodeId,
      targetNodeId: data.targetNodeId.present
          ? data.targetNodeId.value
          : this.targetNodeId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BoardEdge(')
          ..write('id: $id, ')
          ..write('viewId: $viewId, ')
          ..write('sourceNodeId: $sourceNodeId, ')
          ..write('targetNodeId: $targetNodeId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, viewId, sourceNodeId, targetNodeId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BoardEdge &&
          other.id == this.id &&
          other.viewId == this.viewId &&
          other.sourceNodeId == this.sourceNodeId &&
          other.targetNodeId == this.targetNodeId);
}

class BoardEdgesCompanion extends UpdateCompanion<BoardEdge> {
  final Value<String> id;
  final Value<String?> viewId;
  final Value<String?> sourceNodeId;
  final Value<String?> targetNodeId;
  final Value<int> rowid;
  const BoardEdgesCompanion({
    this.id = const Value.absent(),
    this.viewId = const Value.absent(),
    this.sourceNodeId = const Value.absent(),
    this.targetNodeId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BoardEdgesCompanion.insert({
    required String id,
    this.viewId = const Value.absent(),
    this.sourceNodeId = const Value.absent(),
    this.targetNodeId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<BoardEdge> custom({
    Expression<String>? id,
    Expression<String>? viewId,
    Expression<String>? sourceNodeId,
    Expression<String>? targetNodeId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (viewId != null) 'view_id': viewId,
      if (sourceNodeId != null) 'source_node_id': sourceNodeId,
      if (targetNodeId != null) 'target_node_id': targetNodeId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BoardEdgesCompanion copyWith({
    Value<String>? id,
    Value<String?>? viewId,
    Value<String?>? sourceNodeId,
    Value<String?>? targetNodeId,
    Value<int>? rowid,
  }) {
    return BoardEdgesCompanion(
      id: id ?? this.id,
      viewId: viewId ?? this.viewId,
      sourceNodeId: sourceNodeId ?? this.sourceNodeId,
      targetNodeId: targetNodeId ?? this.targetNodeId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (viewId.present) {
      map['view_id'] = Variable<String>(viewId.value);
    }
    if (sourceNodeId.present) {
      map['source_node_id'] = Variable<String>(sourceNodeId.value);
    }
    if (targetNodeId.present) {
      map['target_node_id'] = Variable<String>(targetNodeId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BoardEdgesCompanion(')
          ..write('id: $id, ')
          ..write('viewId: $viewId, ')
          ..write('sourceNodeId: $sourceNodeId, ')
          ..write('targetNodeId: $targetNodeId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BoardGroupsTable extends BoardGroups
    with TableInfo<$BoardGroupsTable, BoardGroup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BoardGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _viewIdMeta = const VerificationMeta('viewId');
  @override
  late final GeneratedColumn<String> viewId = GeneratedColumn<String>(
    'view_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nodeIdsMeta = const VerificationMeta(
    'nodeIds',
  );
  @override
  late final GeneratedColumn<String> nodeIds = GeneratedColumn<String>(
    'node_ids',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, viewId, nodeIds, color];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'board_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<BoardGroup> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('view_id')) {
      context.handle(
        _viewIdMeta,
        viewId.isAcceptableOrUnknown(data['view_id']!, _viewIdMeta),
      );
    }
    if (data.containsKey('node_ids')) {
      context.handle(
        _nodeIdsMeta,
        nodeIds.isAcceptableOrUnknown(data['node_ids']!, _nodeIdsMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BoardGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BoardGroup(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      viewId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}view_id'],
      ),
      nodeIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_ids'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
    );
  }

  @override
  $BoardGroupsTable createAlias(String alias) {
    return $BoardGroupsTable(attachedDatabase, alias);
  }
}

class BoardGroup extends DataClass implements Insertable<BoardGroup> {
  final String id;
  final String? viewId;
  final String? nodeIds;
  final String? color;
  const BoardGroup({required this.id, this.viewId, this.nodeIds, this.color});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || viewId != null) {
      map['view_id'] = Variable<String>(viewId);
    }
    if (!nullToAbsent || nodeIds != null) {
      map['node_ids'] = Variable<String>(nodeIds);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    return map;
  }

  BoardGroupsCompanion toCompanion(bool nullToAbsent) {
    return BoardGroupsCompanion(
      id: Value(id),
      viewId: viewId == null && nullToAbsent
          ? const Value.absent()
          : Value(viewId),
      nodeIds: nodeIds == null && nullToAbsent
          ? const Value.absent()
          : Value(nodeIds),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
    );
  }

  factory BoardGroup.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BoardGroup(
      id: serializer.fromJson<String>(json['id']),
      viewId: serializer.fromJson<String?>(json['viewId']),
      nodeIds: serializer.fromJson<String?>(json['nodeIds']),
      color: serializer.fromJson<String?>(json['color']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'viewId': serializer.toJson<String?>(viewId),
      'nodeIds': serializer.toJson<String?>(nodeIds),
      'color': serializer.toJson<String?>(color),
    };
  }

  BoardGroup copyWith({
    String? id,
    Value<String?> viewId = const Value.absent(),
    Value<String?> nodeIds = const Value.absent(),
    Value<String?> color = const Value.absent(),
  }) => BoardGroup(
    id: id ?? this.id,
    viewId: viewId.present ? viewId.value : this.viewId,
    nodeIds: nodeIds.present ? nodeIds.value : this.nodeIds,
    color: color.present ? color.value : this.color,
  );
  BoardGroup copyWithCompanion(BoardGroupsCompanion data) {
    return BoardGroup(
      id: data.id.present ? data.id.value : this.id,
      viewId: data.viewId.present ? data.viewId.value : this.viewId,
      nodeIds: data.nodeIds.present ? data.nodeIds.value : this.nodeIds,
      color: data.color.present ? data.color.value : this.color,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BoardGroup(')
          ..write('id: $id, ')
          ..write('viewId: $viewId, ')
          ..write('nodeIds: $nodeIds, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, viewId, nodeIds, color);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BoardGroup &&
          other.id == this.id &&
          other.viewId == this.viewId &&
          other.nodeIds == this.nodeIds &&
          other.color == this.color);
}

class BoardGroupsCompanion extends UpdateCompanion<BoardGroup> {
  final Value<String> id;
  final Value<String?> viewId;
  final Value<String?> nodeIds;
  final Value<String?> color;
  final Value<int> rowid;
  const BoardGroupsCompanion({
    this.id = const Value.absent(),
    this.viewId = const Value.absent(),
    this.nodeIds = const Value.absent(),
    this.color = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BoardGroupsCompanion.insert({
    required String id,
    this.viewId = const Value.absent(),
    this.nodeIds = const Value.absent(),
    this.color = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<BoardGroup> custom({
    Expression<String>? id,
    Expression<String>? viewId,
    Expression<String>? nodeIds,
    Expression<String>? color,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (viewId != null) 'view_id': viewId,
      if (nodeIds != null) 'node_ids': nodeIds,
      if (color != null) 'color': color,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BoardGroupsCompanion copyWith({
    Value<String>? id,
    Value<String?>? viewId,
    Value<String?>? nodeIds,
    Value<String?>? color,
    Value<int>? rowid,
  }) {
    return BoardGroupsCompanion(
      id: id ?? this.id,
      viewId: viewId ?? this.viewId,
      nodeIds: nodeIds ?? this.nodeIds,
      color: color ?? this.color,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (viewId.present) {
      map['view_id'] = Variable<String>(viewId.value);
    }
    if (nodeIds.present) {
      map['node_ids'] = Variable<String>(nodeIds.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BoardGroupsCompanion(')
          ..write('id: $id, ')
          ..write('viewId: $viewId, ')
          ..write('nodeIds: $nodeIds, ')
          ..write('color: $color, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BoardTextsTable extends BoardTexts
    with TableInfo<$BoardTextsTable, BoardText> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BoardTextsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _viewIdMeta = const VerificationMeta('viewId');
  @override
  late final GeneratedColumn<String> viewId = GeneratedColumn<String>(
    'view_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _xMeta = const VerificationMeta('x');
  @override
  late final GeneratedColumn<double> x = GeneratedColumn<double>(
    'x',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yMeta = const VerificationMeta('y');
  @override
  late final GeneratedColumn<double> y = GeneratedColumn<double>(
    'y',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, viewId, x, y, content];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'board_texts';
  @override
  VerificationContext validateIntegrity(
    Insertable<BoardText> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('view_id')) {
      context.handle(
        _viewIdMeta,
        viewId.isAcceptableOrUnknown(data['view_id']!, _viewIdMeta),
      );
    }
    if (data.containsKey('x')) {
      context.handle(_xMeta, x.isAcceptableOrUnknown(data['x']!, _xMeta));
    }
    if (data.containsKey('y')) {
      context.handle(_yMeta, y.isAcceptableOrUnknown(data['y']!, _yMeta));
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BoardText map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BoardText(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      viewId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}view_id'],
      ),
      x: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}x'],
      ),
      y: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}y'],
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      ),
    );
  }

  @override
  $BoardTextsTable createAlias(String alias) {
    return $BoardTextsTable(attachedDatabase, alias);
  }
}

class BoardText extends DataClass implements Insertable<BoardText> {
  final String id;
  final String? viewId;
  final double? x;
  final double? y;
  final String? content;
  const BoardText({
    required this.id,
    this.viewId,
    this.x,
    this.y,
    this.content,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || viewId != null) {
      map['view_id'] = Variable<String>(viewId);
    }
    if (!nullToAbsent || x != null) {
      map['x'] = Variable<double>(x);
    }
    if (!nullToAbsent || y != null) {
      map['y'] = Variable<double>(y);
    }
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    return map;
  }

  BoardTextsCompanion toCompanion(bool nullToAbsent) {
    return BoardTextsCompanion(
      id: Value(id),
      viewId: viewId == null && nullToAbsent
          ? const Value.absent()
          : Value(viewId),
      x: x == null && nullToAbsent ? const Value.absent() : Value(x),
      y: y == null && nullToAbsent ? const Value.absent() : Value(y),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
    );
  }

  factory BoardText.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BoardText(
      id: serializer.fromJson<String>(json['id']),
      viewId: serializer.fromJson<String?>(json['viewId']),
      x: serializer.fromJson<double?>(json['x']),
      y: serializer.fromJson<double?>(json['y']),
      content: serializer.fromJson<String?>(json['content']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'viewId': serializer.toJson<String?>(viewId),
      'x': serializer.toJson<double?>(x),
      'y': serializer.toJson<double?>(y),
      'content': serializer.toJson<String?>(content),
    };
  }

  BoardText copyWith({
    String? id,
    Value<String?> viewId = const Value.absent(),
    Value<double?> x = const Value.absent(),
    Value<double?> y = const Value.absent(),
    Value<String?> content = const Value.absent(),
  }) => BoardText(
    id: id ?? this.id,
    viewId: viewId.present ? viewId.value : this.viewId,
    x: x.present ? x.value : this.x,
    y: y.present ? y.value : this.y,
    content: content.present ? content.value : this.content,
  );
  BoardText copyWithCompanion(BoardTextsCompanion data) {
    return BoardText(
      id: data.id.present ? data.id.value : this.id,
      viewId: data.viewId.present ? data.viewId.value : this.viewId,
      x: data.x.present ? data.x.value : this.x,
      y: data.y.present ? data.y.value : this.y,
      content: data.content.present ? data.content.value : this.content,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BoardText(')
          ..write('id: $id, ')
          ..write('viewId: $viewId, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, viewId, x, y, content);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BoardText &&
          other.id == this.id &&
          other.viewId == this.viewId &&
          other.x == this.x &&
          other.y == this.y &&
          other.content == this.content);
}

class BoardTextsCompanion extends UpdateCompanion<BoardText> {
  final Value<String> id;
  final Value<String?> viewId;
  final Value<double?> x;
  final Value<double?> y;
  final Value<String?> content;
  final Value<int> rowid;
  const BoardTextsCompanion({
    this.id = const Value.absent(),
    this.viewId = const Value.absent(),
    this.x = const Value.absent(),
    this.y = const Value.absent(),
    this.content = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BoardTextsCompanion.insert({
    required String id,
    this.viewId = const Value.absent(),
    this.x = const Value.absent(),
    this.y = const Value.absent(),
    this.content = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<BoardText> custom({
    Expression<String>? id,
    Expression<String>? viewId,
    Expression<double>? x,
    Expression<double>? y,
    Expression<String>? content,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (viewId != null) 'view_id': viewId,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (content != null) 'content': content,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BoardTextsCompanion copyWith({
    Value<String>? id,
    Value<String?>? viewId,
    Value<double?>? x,
    Value<double?>? y,
    Value<String?>? content,
    Value<int>? rowid,
  }) {
    return BoardTextsCompanion(
      id: id ?? this.id,
      viewId: viewId ?? this.viewId,
      x: x ?? this.x,
      y: y ?? this.y,
      content: content ?? this.content,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (viewId.present) {
      map['view_id'] = Variable<String>(viewId.value);
    }
    if (x.present) {
      map['x'] = Variable<double>(x.value);
    }
    if (y.present) {
      map['y'] = Variable<double>(y.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BoardTextsCompanion(')
          ..write('id: $id, ')
          ..write('viewId: $viewId, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('content: $content, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BoardStrokesTable extends BoardStrokes
    with TableInfo<$BoardStrokesTable, BoardStroke> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BoardStrokesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _viewIdMeta = const VerificationMeta('viewId');
  @override
  late final GeneratedColumn<String> viewId = GeneratedColumn<String>(
    'view_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _zIndexMeta = const VerificationMeta('zIndex');
  @override
  late final GeneratedColumn<int> zIndex = GeneratedColumn<int>(
    'z_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _pointsMeta = const VerificationMeta('points');
  @override
  late final GeneratedColumn<String> points = GeneratedColumn<String>(
    'points',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<double> width = GeneratedColumn<double>(
    'width',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    viewId,
    groupId,
    zIndex,
    points,
    color,
    width,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'board_strokes';
  @override
  VerificationContext validateIntegrity(
    Insertable<BoardStroke> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('view_id')) {
      context.handle(
        _viewIdMeta,
        viewId.isAcceptableOrUnknown(data['view_id']!, _viewIdMeta),
      );
    } else if (isInserting) {
      context.missing(_viewIdMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    }
    if (data.containsKey('z_index')) {
      context.handle(
        _zIndexMeta,
        zIndex.isAcceptableOrUnknown(data['z_index']!, _zIndexMeta),
      );
    }
    if (data.containsKey('points')) {
      context.handle(
        _pointsMeta,
        points.isAcceptableOrUnknown(data['points']!, _pointsMeta),
      );
    } else if (isInserting) {
      context.missing(_pointsMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    } else if (isInserting) {
      context.missing(_widthMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BoardStroke map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BoardStroke(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      viewId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}view_id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      ),
      zIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}z_index'],
      )!,
      points: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}points'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}width'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $BoardStrokesTable createAlias(String alias) {
    return $BoardStrokesTable(attachedDatabase, alias);
  }
}

class BoardStroke extends DataClass implements Insertable<BoardStroke> {
  final String id;
  final String viewId;
  final String? groupId;
  final int zIndex;
  final String points;
  final String color;
  final double width;
  final String createdAt;
  const BoardStroke({
    required this.id,
    required this.viewId,
    this.groupId,
    required this.zIndex,
    required this.points,
    required this.color,
    required this.width,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['view_id'] = Variable<String>(viewId);
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<String>(groupId);
    }
    map['z_index'] = Variable<int>(zIndex);
    map['points'] = Variable<String>(points);
    map['color'] = Variable<String>(color);
    map['width'] = Variable<double>(width);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  BoardStrokesCompanion toCompanion(bool nullToAbsent) {
    return BoardStrokesCompanion(
      id: Value(id),
      viewId: Value(viewId),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      zIndex: Value(zIndex),
      points: Value(points),
      color: Value(color),
      width: Value(width),
      createdAt: Value(createdAt),
    );
  }

  factory BoardStroke.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BoardStroke(
      id: serializer.fromJson<String>(json['id']),
      viewId: serializer.fromJson<String>(json['viewId']),
      groupId: serializer.fromJson<String?>(json['groupId']),
      zIndex: serializer.fromJson<int>(json['zIndex']),
      points: serializer.fromJson<String>(json['points']),
      color: serializer.fromJson<String>(json['color']),
      width: serializer.fromJson<double>(json['width']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'viewId': serializer.toJson<String>(viewId),
      'groupId': serializer.toJson<String?>(groupId),
      'zIndex': serializer.toJson<int>(zIndex),
      'points': serializer.toJson<String>(points),
      'color': serializer.toJson<String>(color),
      'width': serializer.toJson<double>(width),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  BoardStroke copyWith({
    String? id,
    String? viewId,
    Value<String?> groupId = const Value.absent(),
    int? zIndex,
    String? points,
    String? color,
    double? width,
    String? createdAt,
  }) => BoardStroke(
    id: id ?? this.id,
    viewId: viewId ?? this.viewId,
    groupId: groupId.present ? groupId.value : this.groupId,
    zIndex: zIndex ?? this.zIndex,
    points: points ?? this.points,
    color: color ?? this.color,
    width: width ?? this.width,
    createdAt: createdAt ?? this.createdAt,
  );
  BoardStroke copyWithCompanion(BoardStrokesCompanion data) {
    return BoardStroke(
      id: data.id.present ? data.id.value : this.id,
      viewId: data.viewId.present ? data.viewId.value : this.viewId,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      zIndex: data.zIndex.present ? data.zIndex.value : this.zIndex,
      points: data.points.present ? data.points.value : this.points,
      color: data.color.present ? data.color.value : this.color,
      width: data.width.present ? data.width.value : this.width,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BoardStroke(')
          ..write('id: $id, ')
          ..write('viewId: $viewId, ')
          ..write('groupId: $groupId, ')
          ..write('zIndex: $zIndex, ')
          ..write('points: $points, ')
          ..write('color: $color, ')
          ..write('width: $width, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, viewId, groupId, zIndex, points, color, width, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BoardStroke &&
          other.id == this.id &&
          other.viewId == this.viewId &&
          other.groupId == this.groupId &&
          other.zIndex == this.zIndex &&
          other.points == this.points &&
          other.color == this.color &&
          other.width == this.width &&
          other.createdAt == this.createdAt);
}

class BoardStrokesCompanion extends UpdateCompanion<BoardStroke> {
  final Value<String> id;
  final Value<String> viewId;
  final Value<String?> groupId;
  final Value<int> zIndex;
  final Value<String> points;
  final Value<String> color;
  final Value<double> width;
  final Value<String> createdAt;
  final Value<int> rowid;
  const BoardStrokesCompanion({
    this.id = const Value.absent(),
    this.viewId = const Value.absent(),
    this.groupId = const Value.absent(),
    this.zIndex = const Value.absent(),
    this.points = const Value.absent(),
    this.color = const Value.absent(),
    this.width = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BoardStrokesCompanion.insert({
    required String id,
    required String viewId,
    this.groupId = const Value.absent(),
    this.zIndex = const Value.absent(),
    required String points,
    required String color,
    required double width,
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       viewId = Value(viewId),
       points = Value(points),
       color = Value(color),
       width = Value(width),
       createdAt = Value(createdAt);
  static Insertable<BoardStroke> custom({
    Expression<String>? id,
    Expression<String>? viewId,
    Expression<String>? groupId,
    Expression<int>? zIndex,
    Expression<String>? points,
    Expression<String>? color,
    Expression<double>? width,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (viewId != null) 'view_id': viewId,
      if (groupId != null) 'group_id': groupId,
      if (zIndex != null) 'z_index': zIndex,
      if (points != null) 'points': points,
      if (color != null) 'color': color,
      if (width != null) 'width': width,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BoardStrokesCompanion copyWith({
    Value<String>? id,
    Value<String>? viewId,
    Value<String?>? groupId,
    Value<int>? zIndex,
    Value<String>? points,
    Value<String>? color,
    Value<double>? width,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return BoardStrokesCompanion(
      id: id ?? this.id,
      viewId: viewId ?? this.viewId,
      groupId: groupId ?? this.groupId,
      zIndex: zIndex ?? this.zIndex,
      points: points ?? this.points,
      color: color ?? this.color,
      width: width ?? this.width,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (viewId.present) {
      map['view_id'] = Variable<String>(viewId.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (zIndex.present) {
      map['z_index'] = Variable<int>(zIndex.value);
    }
    if (points.present) {
      map['points'] = Variable<String>(points.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (width.present) {
      map['width'] = Variable<double>(width.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BoardStrokesCompanion(')
          ..write('id: $id, ')
          ..write('viewId: $viewId, ')
          ..write('groupId: $groupId, ')
          ..write('zIndex: $zIndex, ')
          ..write('points: $points, ')
          ..write('color: $color, ')
          ..write('width: $width, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BoardAlbumsTable extends BoardAlbums
    with TableInfo<$BoardAlbumsTable, BoardAlbum> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BoardAlbumsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceViewIdMeta = const VerificationMeta(
    'sourceViewId',
  );
  @override
  late final GeneratedColumn<String> sourceViewId = GeneratedColumn<String>(
    'source_view_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _strokesJsonMeta = const VerificationMeta(
    'strokesJson',
  );
  @override
  late final GeneratedColumn<String> strokesJson = GeneratedColumn<String>(
    'strokes_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thumbnailBase64Meta = const VerificationMeta(
    'thumbnailBase64',
  );
  @override
  late final GeneratedColumn<String> thumbnailBase64 = GeneratedColumn<String>(
    'thumbnail_base64',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    sourceViewId,
    strokesJson,
    thumbnailBase64,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'board_albums';
  @override
  VerificationContext validateIntegrity(
    Insertable<BoardAlbum> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('source_view_id')) {
      context.handle(
        _sourceViewIdMeta,
        sourceViewId.isAcceptableOrUnknown(
          data['source_view_id']!,
          _sourceViewIdMeta,
        ),
      );
    }
    if (data.containsKey('strokes_json')) {
      context.handle(
        _strokesJsonMeta,
        strokesJson.isAcceptableOrUnknown(
          data['strokes_json']!,
          _strokesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_strokesJsonMeta);
    }
    if (data.containsKey('thumbnail_base64')) {
      context.handle(
        _thumbnailBase64Meta,
        thumbnailBase64.isAcceptableOrUnknown(
          data['thumbnail_base64']!,
          _thumbnailBase64Meta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BoardAlbum map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BoardAlbum(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      sourceViewId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_view_id'],
      ),
      strokesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}strokes_json'],
      )!,
      thumbnailBase64: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_base64'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $BoardAlbumsTable createAlias(String alias) {
    return $BoardAlbumsTable(attachedDatabase, alias);
  }
}

class BoardAlbum extends DataClass implements Insertable<BoardAlbum> {
  final String id;
  final String? title;
  final String? sourceViewId;
  final String strokesJson;
  final String? thumbnailBase64;
  final String createdAt;
  final String? updatedAt;
  const BoardAlbum({
    required this.id,
    this.title,
    this.sourceViewId,
    required this.strokesJson,
    this.thumbnailBase64,
    required this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || sourceViewId != null) {
      map['source_view_id'] = Variable<String>(sourceViewId);
    }
    map['strokes_json'] = Variable<String>(strokesJson);
    if (!nullToAbsent || thumbnailBase64 != null) {
      map['thumbnail_base64'] = Variable<String>(thumbnailBase64);
    }
    map['created_at'] = Variable<String>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    return map;
  }

  BoardAlbumsCompanion toCompanion(bool nullToAbsent) {
    return BoardAlbumsCompanion(
      id: Value(id),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      sourceViewId: sourceViewId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceViewId),
      strokesJson: Value(strokesJson),
      thumbnailBase64: thumbnailBase64 == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailBase64),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory BoardAlbum.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BoardAlbum(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String?>(json['title']),
      sourceViewId: serializer.fromJson<String?>(json['sourceViewId']),
      strokesJson: serializer.fromJson<String>(json['strokesJson']),
      thumbnailBase64: serializer.fromJson<String?>(json['thumbnailBase64']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String?>(title),
      'sourceViewId': serializer.toJson<String?>(sourceViewId),
      'strokesJson': serializer.toJson<String>(strokesJson),
      'thumbnailBase64': serializer.toJson<String?>(thumbnailBase64),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String?>(updatedAt),
    };
  }

  BoardAlbum copyWith({
    String? id,
    Value<String?> title = const Value.absent(),
    Value<String?> sourceViewId = const Value.absent(),
    String? strokesJson,
    Value<String?> thumbnailBase64 = const Value.absent(),
    String? createdAt,
    Value<String?> updatedAt = const Value.absent(),
  }) => BoardAlbum(
    id: id ?? this.id,
    title: title.present ? title.value : this.title,
    sourceViewId: sourceViewId.present ? sourceViewId.value : this.sourceViewId,
    strokesJson: strokesJson ?? this.strokesJson,
    thumbnailBase64: thumbnailBase64.present
        ? thumbnailBase64.value
        : this.thumbnailBase64,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  BoardAlbum copyWithCompanion(BoardAlbumsCompanion data) {
    return BoardAlbum(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      sourceViewId: data.sourceViewId.present
          ? data.sourceViewId.value
          : this.sourceViewId,
      strokesJson: data.strokesJson.present
          ? data.strokesJson.value
          : this.strokesJson,
      thumbnailBase64: data.thumbnailBase64.present
          ? data.thumbnailBase64.value
          : this.thumbnailBase64,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BoardAlbum(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('sourceViewId: $sourceViewId, ')
          ..write('strokesJson: $strokesJson, ')
          ..write('thumbnailBase64: $thumbnailBase64, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    sourceViewId,
    strokesJson,
    thumbnailBase64,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BoardAlbum &&
          other.id == this.id &&
          other.title == this.title &&
          other.sourceViewId == this.sourceViewId &&
          other.strokesJson == this.strokesJson &&
          other.thumbnailBase64 == this.thumbnailBase64 &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BoardAlbumsCompanion extends UpdateCompanion<BoardAlbum> {
  final Value<String> id;
  final Value<String?> title;
  final Value<String?> sourceViewId;
  final Value<String> strokesJson;
  final Value<String?> thumbnailBase64;
  final Value<String> createdAt;
  final Value<String?> updatedAt;
  final Value<int> rowid;
  const BoardAlbumsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.sourceViewId = const Value.absent(),
    this.strokesJson = const Value.absent(),
    this.thumbnailBase64 = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BoardAlbumsCompanion.insert({
    required String id,
    this.title = const Value.absent(),
    this.sourceViewId = const Value.absent(),
    required String strokesJson,
    this.thumbnailBase64 = const Value.absent(),
    required String createdAt,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       strokesJson = Value(strokesJson),
       createdAt = Value(createdAt);
  static Insertable<BoardAlbum> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? sourceViewId,
    Expression<String>? strokesJson,
    Expression<String>? thumbnailBase64,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (sourceViewId != null) 'source_view_id': sourceViewId,
      if (strokesJson != null) 'strokes_json': strokesJson,
      if (thumbnailBase64 != null) 'thumbnail_base64': thumbnailBase64,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BoardAlbumsCompanion copyWith({
    Value<String>? id,
    Value<String?>? title,
    Value<String?>? sourceViewId,
    Value<String>? strokesJson,
    Value<String?>? thumbnailBase64,
    Value<String>? createdAt,
    Value<String?>? updatedAt,
    Value<int>? rowid,
  }) {
    return BoardAlbumsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      sourceViewId: sourceViewId ?? this.sourceViewId,
      strokesJson: strokesJson ?? this.strokesJson,
      thumbnailBase64: thumbnailBase64 ?? this.thumbnailBase64,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (sourceViewId.present) {
      map['source_view_id'] = Variable<String>(sourceViewId.value);
    }
    if (strokesJson.present) {
      map['strokes_json'] = Variable<String>(strokesJson.value);
    }
    if (thumbnailBase64.present) {
      map['thumbnail_base64'] = Variable<String>(thumbnailBase64.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BoardAlbumsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('sourceViewId: $sourceViewId, ')
          ..write('strokesJson: $strokesJson, ')
          ..write('thumbnailBase64: $thumbnailBase64, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NoteBookLinksTable extends NoteBookLinks
    with TableInfo<$NoteBookLinksTable, NoteBookLink> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NoteBookLinksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
    'note_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _linkTypeMeta = const VerificationMeta(
    'linkType',
  );
  @override
  late final GeneratedColumn<String> linkType = GeneratedColumn<String>(
    'link_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _linkTextMeta = const VerificationMeta(
    'linkText',
  );
  @override
  late final GeneratedColumn<String> linkText = GeneratedColumn<String>(
    'link_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contextMeta = const VerificationMeta(
    'context',
  );
  @override
  late final GeneratedColumn<String> context = GeneratedColumn<String>(
    'context',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    noteId,
    bookId,
    linkType,
    linkText,
    context,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'note_book_links';
  @override
  VerificationContext validateIntegrity(
    Insertable<NoteBookLink> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('note_id')) {
      context.handle(
        _noteIdMeta,
        noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('link_type')) {
      context.handle(
        _linkTypeMeta,
        linkType.isAcceptableOrUnknown(data['link_type']!, _linkTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_linkTypeMeta);
    }
    if (data.containsKey('link_text')) {
      context.handle(
        _linkTextMeta,
        linkText.isAcceptableOrUnknown(data['link_text']!, _linkTextMeta),
      );
    }
    if (data.containsKey('context')) {
      context.handle(
        _contextMeta,
        this.context.isAcceptableOrUnknown(data['context']!, _contextMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NoteBookLink map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteBookLink(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      noteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      linkType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}link_type'],
      )!,
      linkText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}link_text'],
      ),
      context: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $NoteBookLinksTable createAlias(String alias) {
    return $NoteBookLinksTable(attachedDatabase, alias);
  }
}

class NoteBookLink extends DataClass implements Insertable<NoteBookLink> {
  final String id;
  final String noteId;
  final String bookId;
  final String linkType;
  final String? linkText;
  final String? context;
  final String createdAt;
  const NoteBookLink({
    required this.id,
    required this.noteId,
    required this.bookId,
    required this.linkType,
    this.linkText,
    this.context,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['note_id'] = Variable<String>(noteId);
    map['book_id'] = Variable<String>(bookId);
    map['link_type'] = Variable<String>(linkType);
    if (!nullToAbsent || linkText != null) {
      map['link_text'] = Variable<String>(linkText);
    }
    if (!nullToAbsent || context != null) {
      map['context'] = Variable<String>(context);
    }
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  NoteBookLinksCompanion toCompanion(bool nullToAbsent) {
    return NoteBookLinksCompanion(
      id: Value(id),
      noteId: Value(noteId),
      bookId: Value(bookId),
      linkType: Value(linkType),
      linkText: linkText == null && nullToAbsent
          ? const Value.absent()
          : Value(linkText),
      context: context == null && nullToAbsent
          ? const Value.absent()
          : Value(context),
      createdAt: Value(createdAt),
    );
  }

  factory NoteBookLink.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteBookLink(
      id: serializer.fromJson<String>(json['id']),
      noteId: serializer.fromJson<String>(json['noteId']),
      bookId: serializer.fromJson<String>(json['bookId']),
      linkType: serializer.fromJson<String>(json['linkType']),
      linkText: serializer.fromJson<String?>(json['linkText']),
      context: serializer.fromJson<String?>(json['context']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'noteId': serializer.toJson<String>(noteId),
      'bookId': serializer.toJson<String>(bookId),
      'linkType': serializer.toJson<String>(linkType),
      'linkText': serializer.toJson<String?>(linkText),
      'context': serializer.toJson<String?>(context),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  NoteBookLink copyWith({
    String? id,
    String? noteId,
    String? bookId,
    String? linkType,
    Value<String?> linkText = const Value.absent(),
    Value<String?> context = const Value.absent(),
    String? createdAt,
  }) => NoteBookLink(
    id: id ?? this.id,
    noteId: noteId ?? this.noteId,
    bookId: bookId ?? this.bookId,
    linkType: linkType ?? this.linkType,
    linkText: linkText.present ? linkText.value : this.linkText,
    context: context.present ? context.value : this.context,
    createdAt: createdAt ?? this.createdAt,
  );
  NoteBookLink copyWithCompanion(NoteBookLinksCompanion data) {
    return NoteBookLink(
      id: data.id.present ? data.id.value : this.id,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      linkType: data.linkType.present ? data.linkType.value : this.linkType,
      linkText: data.linkText.present ? data.linkText.value : this.linkText,
      context: data.context.present ? data.context.value : this.context,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteBookLink(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('bookId: $bookId, ')
          ..write('linkType: $linkType, ')
          ..write('linkText: $linkText, ')
          ..write('context: $context, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, noteId, bookId, linkType, linkText, context, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteBookLink &&
          other.id == this.id &&
          other.noteId == this.noteId &&
          other.bookId == this.bookId &&
          other.linkType == this.linkType &&
          other.linkText == this.linkText &&
          other.context == this.context &&
          other.createdAt == this.createdAt);
}

class NoteBookLinksCompanion extends UpdateCompanion<NoteBookLink> {
  final Value<String> id;
  final Value<String> noteId;
  final Value<String> bookId;
  final Value<String> linkType;
  final Value<String?> linkText;
  final Value<String?> context;
  final Value<String> createdAt;
  final Value<int> rowid;
  const NoteBookLinksCompanion({
    this.id = const Value.absent(),
    this.noteId = const Value.absent(),
    this.bookId = const Value.absent(),
    this.linkType = const Value.absent(),
    this.linkText = const Value.absent(),
    this.context = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NoteBookLinksCompanion.insert({
    required String id,
    required String noteId,
    required String bookId,
    required String linkType,
    this.linkText = const Value.absent(),
    this.context = const Value.absent(),
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       noteId = Value(noteId),
       bookId = Value(bookId),
       linkType = Value(linkType),
       createdAt = Value(createdAt);
  static Insertable<NoteBookLink> custom({
    Expression<String>? id,
    Expression<String>? noteId,
    Expression<String>? bookId,
    Expression<String>? linkType,
    Expression<String>? linkText,
    Expression<String>? context,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (noteId != null) 'note_id': noteId,
      if (bookId != null) 'book_id': bookId,
      if (linkType != null) 'link_type': linkType,
      if (linkText != null) 'link_text': linkText,
      if (context != null) 'context': context,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NoteBookLinksCompanion copyWith({
    Value<String>? id,
    Value<String>? noteId,
    Value<String>? bookId,
    Value<String>? linkType,
    Value<String?>? linkText,
    Value<String?>? context,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return NoteBookLinksCompanion(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      bookId: bookId ?? this.bookId,
      linkType: linkType ?? this.linkType,
      linkText: linkText ?? this.linkText,
      context: context ?? this.context,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (linkType.present) {
      map['link_type'] = Variable<String>(linkType.value);
    }
    if (linkText.present) {
      map['link_text'] = Variable<String>(linkText.value);
    }
    if (context.present) {
      map['context'] = Variable<String>(context.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NoteBookLinksCompanion(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('bookId: $bookId, ')
          ..write('linkType: $linkType, ')
          ..write('linkText: $linkText, ')
          ..write('context: $context, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NoteNoteLinksTable extends NoteNoteLinks
    with TableInfo<$NoteNoteLinksTable, NoteNoteLink> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NoteNoteLinksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceNoteIdMeta = const VerificationMeta(
    'sourceNoteId',
  );
  @override
  late final GeneratedColumn<String> sourceNoteId = GeneratedColumn<String>(
    'source_note_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetNoteIdMeta = const VerificationMeta(
    'targetNoteId',
  );
  @override
  late final GeneratedColumn<String> targetNoteId = GeneratedColumn<String>(
    'target_note_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _linkTypeMeta = const VerificationMeta(
    'linkType',
  );
  @override
  late final GeneratedColumn<String> linkType = GeneratedColumn<String>(
    'link_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _linkTextMeta = const VerificationMeta(
    'linkText',
  );
  @override
  late final GeneratedColumn<String> linkText = GeneratedColumn<String>(
    'link_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceNoteId,
    targetNoteId,
    linkType,
    linkText,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'note_note_links';
  @override
  VerificationContext validateIntegrity(
    Insertable<NoteNoteLink> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_note_id')) {
      context.handle(
        _sourceNoteIdMeta,
        sourceNoteId.isAcceptableOrUnknown(
          data['source_note_id']!,
          _sourceNoteIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceNoteIdMeta);
    }
    if (data.containsKey('target_note_id')) {
      context.handle(
        _targetNoteIdMeta,
        targetNoteId.isAcceptableOrUnknown(
          data['target_note_id']!,
          _targetNoteIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetNoteIdMeta);
    }
    if (data.containsKey('link_type')) {
      context.handle(
        _linkTypeMeta,
        linkType.isAcceptableOrUnknown(data['link_type']!, _linkTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_linkTypeMeta);
    }
    if (data.containsKey('link_text')) {
      context.handle(
        _linkTextMeta,
        linkText.isAcceptableOrUnknown(data['link_text']!, _linkTextMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NoteNoteLink map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteNoteLink(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceNoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_note_id'],
      )!,
      targetNoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_note_id'],
      )!,
      linkType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}link_type'],
      )!,
      linkText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}link_text'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $NoteNoteLinksTable createAlias(String alias) {
    return $NoteNoteLinksTable(attachedDatabase, alias);
  }
}

class NoteNoteLink extends DataClass implements Insertable<NoteNoteLink> {
  final String id;
  final String sourceNoteId;
  final String targetNoteId;
  final String linkType;
  final String? linkText;
  final String createdAt;
  const NoteNoteLink({
    required this.id,
    required this.sourceNoteId,
    required this.targetNoteId,
    required this.linkType,
    this.linkText,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_note_id'] = Variable<String>(sourceNoteId);
    map['target_note_id'] = Variable<String>(targetNoteId);
    map['link_type'] = Variable<String>(linkType);
    if (!nullToAbsent || linkText != null) {
      map['link_text'] = Variable<String>(linkText);
    }
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  NoteNoteLinksCompanion toCompanion(bool nullToAbsent) {
    return NoteNoteLinksCompanion(
      id: Value(id),
      sourceNoteId: Value(sourceNoteId),
      targetNoteId: Value(targetNoteId),
      linkType: Value(linkType),
      linkText: linkText == null && nullToAbsent
          ? const Value.absent()
          : Value(linkText),
      createdAt: Value(createdAt),
    );
  }

  factory NoteNoteLink.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteNoteLink(
      id: serializer.fromJson<String>(json['id']),
      sourceNoteId: serializer.fromJson<String>(json['sourceNoteId']),
      targetNoteId: serializer.fromJson<String>(json['targetNoteId']),
      linkType: serializer.fromJson<String>(json['linkType']),
      linkText: serializer.fromJson<String?>(json['linkText']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceNoteId': serializer.toJson<String>(sourceNoteId),
      'targetNoteId': serializer.toJson<String>(targetNoteId),
      'linkType': serializer.toJson<String>(linkType),
      'linkText': serializer.toJson<String?>(linkText),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  NoteNoteLink copyWith({
    String? id,
    String? sourceNoteId,
    String? targetNoteId,
    String? linkType,
    Value<String?> linkText = const Value.absent(),
    String? createdAt,
  }) => NoteNoteLink(
    id: id ?? this.id,
    sourceNoteId: sourceNoteId ?? this.sourceNoteId,
    targetNoteId: targetNoteId ?? this.targetNoteId,
    linkType: linkType ?? this.linkType,
    linkText: linkText.present ? linkText.value : this.linkText,
    createdAt: createdAt ?? this.createdAt,
  );
  NoteNoteLink copyWithCompanion(NoteNoteLinksCompanion data) {
    return NoteNoteLink(
      id: data.id.present ? data.id.value : this.id,
      sourceNoteId: data.sourceNoteId.present
          ? data.sourceNoteId.value
          : this.sourceNoteId,
      targetNoteId: data.targetNoteId.present
          ? data.targetNoteId.value
          : this.targetNoteId,
      linkType: data.linkType.present ? data.linkType.value : this.linkType,
      linkText: data.linkText.present ? data.linkText.value : this.linkText,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteNoteLink(')
          ..write('id: $id, ')
          ..write('sourceNoteId: $sourceNoteId, ')
          ..write('targetNoteId: $targetNoteId, ')
          ..write('linkType: $linkType, ')
          ..write('linkText: $linkText, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceNoteId,
    targetNoteId,
    linkType,
    linkText,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteNoteLink &&
          other.id == this.id &&
          other.sourceNoteId == this.sourceNoteId &&
          other.targetNoteId == this.targetNoteId &&
          other.linkType == this.linkType &&
          other.linkText == this.linkText &&
          other.createdAt == this.createdAt);
}

class NoteNoteLinksCompanion extends UpdateCompanion<NoteNoteLink> {
  final Value<String> id;
  final Value<String> sourceNoteId;
  final Value<String> targetNoteId;
  final Value<String> linkType;
  final Value<String?> linkText;
  final Value<String> createdAt;
  final Value<int> rowid;
  const NoteNoteLinksCompanion({
    this.id = const Value.absent(),
    this.sourceNoteId = const Value.absent(),
    this.targetNoteId = const Value.absent(),
    this.linkType = const Value.absent(),
    this.linkText = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NoteNoteLinksCompanion.insert({
    required String id,
    required String sourceNoteId,
    required String targetNoteId,
    required String linkType,
    this.linkText = const Value.absent(),
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourceNoteId = Value(sourceNoteId),
       targetNoteId = Value(targetNoteId),
       linkType = Value(linkType),
       createdAt = Value(createdAt);
  static Insertable<NoteNoteLink> custom({
    Expression<String>? id,
    Expression<String>? sourceNoteId,
    Expression<String>? targetNoteId,
    Expression<String>? linkType,
    Expression<String>? linkText,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceNoteId != null) 'source_note_id': sourceNoteId,
      if (targetNoteId != null) 'target_note_id': targetNoteId,
      if (linkType != null) 'link_type': linkType,
      if (linkText != null) 'link_text': linkText,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NoteNoteLinksCompanion copyWith({
    Value<String>? id,
    Value<String>? sourceNoteId,
    Value<String>? targetNoteId,
    Value<String>? linkType,
    Value<String?>? linkText,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return NoteNoteLinksCompanion(
      id: id ?? this.id,
      sourceNoteId: sourceNoteId ?? this.sourceNoteId,
      targetNoteId: targetNoteId ?? this.targetNoteId,
      linkType: linkType ?? this.linkType,
      linkText: linkText ?? this.linkText,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceNoteId.present) {
      map['source_note_id'] = Variable<String>(sourceNoteId.value);
    }
    if (targetNoteId.present) {
      map['target_note_id'] = Variable<String>(targetNoteId.value);
    }
    if (linkType.present) {
      map['link_type'] = Variable<String>(linkType.value);
    }
    if (linkText.present) {
      map['link_text'] = Variable<String>(linkText.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NoteNoteLinksCompanion(')
          ..write('id: $id, ')
          ..write('sourceNoteId: $sourceNoteId, ')
          ..write('targetNoteId: $targetNoteId, ')
          ..write('linkType: $linkType, ')
          ..write('linkText: $linkText, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SparksTable extends Sparks with TableInfo<$SparksTable, SparkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SparksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _anchorNoteIdMeta = const VerificationMeta(
    'anchorNoteId',
  );
  @override
  late final GeneratedColumn<String> anchorNoteId = GeneratedColumn<String>(
    'anchor_note_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _anchorLocationMeta = const VerificationMeta(
    'anchorLocation',
  );
  @override
  late final GeneratedColumn<String> anchorLocation = GeneratedColumn<String>(
    'anchor_location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    content,
    anchorNoteId,
    anchorLocation,
    status,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sparks';
  @override
  VerificationContext validateIntegrity(
    Insertable<SparkRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('anchor_note_id')) {
      context.handle(
        _anchorNoteIdMeta,
        anchorNoteId.isAcceptableOrUnknown(
          data['anchor_note_id']!,
          _anchorNoteIdMeta,
        ),
      );
    }
    if (data.containsKey('anchor_location')) {
      context.handle(
        _anchorLocationMeta,
        anchorLocation.isAcceptableOrUnknown(
          data['anchor_location']!,
          _anchorLocationMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SparkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SparkRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      anchorNoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}anchor_note_id'],
      ),
      anchorLocation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}anchor_location'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $SparksTable createAlias(String alias) {
    return $SparksTable(attachedDatabase, alias);
  }
}

class SparkRow extends DataClass implements Insertable<SparkRow> {
  final String id;
  final String content;
  final String? anchorNoteId;
  final String? anchorLocation;
  final String status;
  final String createdAt;
  final String? updatedAt;
  const SparkRow({
    required this.id,
    required this.content,
    this.anchorNoteId,
    this.anchorLocation,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || anchorNoteId != null) {
      map['anchor_note_id'] = Variable<String>(anchorNoteId);
    }
    if (!nullToAbsent || anchorLocation != null) {
      map['anchor_location'] = Variable<String>(anchorLocation);
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<String>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    return map;
  }

  SparksCompanion toCompanion(bool nullToAbsent) {
    return SparksCompanion(
      id: Value(id),
      content: Value(content),
      anchorNoteId: anchorNoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(anchorNoteId),
      anchorLocation: anchorLocation == null && nullToAbsent
          ? const Value.absent()
          : Value(anchorLocation),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory SparkRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SparkRow(
      id: serializer.fromJson<String>(json['id']),
      content: serializer.fromJson<String>(json['content']),
      anchorNoteId: serializer.fromJson<String?>(json['anchorNoteId']),
      anchorLocation: serializer.fromJson<String?>(json['anchorLocation']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'content': serializer.toJson<String>(content),
      'anchorNoteId': serializer.toJson<String?>(anchorNoteId),
      'anchorLocation': serializer.toJson<String?>(anchorLocation),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String?>(updatedAt),
    };
  }

  SparkRow copyWith({
    String? id,
    String? content,
    Value<String?> anchorNoteId = const Value.absent(),
    Value<String?> anchorLocation = const Value.absent(),
    String? status,
    String? createdAt,
    Value<String?> updatedAt = const Value.absent(),
  }) => SparkRow(
    id: id ?? this.id,
    content: content ?? this.content,
    anchorNoteId: anchorNoteId.present ? anchorNoteId.value : this.anchorNoteId,
    anchorLocation: anchorLocation.present
        ? anchorLocation.value
        : this.anchorLocation,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  SparkRow copyWithCompanion(SparksCompanion data) {
    return SparkRow(
      id: data.id.present ? data.id.value : this.id,
      content: data.content.present ? data.content.value : this.content,
      anchorNoteId: data.anchorNoteId.present
          ? data.anchorNoteId.value
          : this.anchorNoteId,
      anchorLocation: data.anchorLocation.present
          ? data.anchorLocation.value
          : this.anchorLocation,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SparkRow(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('anchorNoteId: $anchorNoteId, ')
          ..write('anchorLocation: $anchorLocation, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    content,
    anchorNoteId,
    anchorLocation,
    status,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SparkRow &&
          other.id == this.id &&
          other.content == this.content &&
          other.anchorNoteId == this.anchorNoteId &&
          other.anchorLocation == this.anchorLocation &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SparksCompanion extends UpdateCompanion<SparkRow> {
  final Value<String> id;
  final Value<String> content;
  final Value<String?> anchorNoteId;
  final Value<String?> anchorLocation;
  final Value<String> status;
  final Value<String> createdAt;
  final Value<String?> updatedAt;
  final Value<int> rowid;
  const SparksCompanion({
    this.id = const Value.absent(),
    this.content = const Value.absent(),
    this.anchorNoteId = const Value.absent(),
    this.anchorLocation = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SparksCompanion.insert({
    required String id,
    required String content,
    this.anchorNoteId = const Value.absent(),
    this.anchorLocation = const Value.absent(),
    this.status = const Value.absent(),
    required String createdAt,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       content = Value(content),
       createdAt = Value(createdAt);
  static Insertable<SparkRow> custom({
    Expression<String>? id,
    Expression<String>? content,
    Expression<String>? anchorNoteId,
    Expression<String>? anchorLocation,
    Expression<String>? status,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (content != null) 'content': content,
      if (anchorNoteId != null) 'anchor_note_id': anchorNoteId,
      if (anchorLocation != null) 'anchor_location': anchorLocation,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SparksCompanion copyWith({
    Value<String>? id,
    Value<String>? content,
    Value<String?>? anchorNoteId,
    Value<String?>? anchorLocation,
    Value<String>? status,
    Value<String>? createdAt,
    Value<String?>? updatedAt,
    Value<int>? rowid,
  }) {
    return SparksCompanion(
      id: id ?? this.id,
      content: content ?? this.content,
      anchorNoteId: anchorNoteId ?? this.anchorNoteId,
      anchorLocation: anchorLocation ?? this.anchorLocation,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (anchorNoteId.present) {
      map['anchor_note_id'] = Variable<String>(anchorNoteId.value);
    }
    if (anchorLocation.present) {
      map['anchor_location'] = Variable<String>(anchorLocation.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SparksCompanion(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('anchorNoteId: $anchorNoteId, ')
          ..write('anchorLocation: $anchorLocation, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NodeAnnotationsTable extends NodeAnnotations
    with TableInfo<$NodeAnnotationsTable, NodeAnnotation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NodeAnnotationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _strokesJsonMeta = const VerificationMeta(
    'strokesJson',
  );
  @override
  late final GeneratedColumn<String> strokesJson = GeneratedColumn<String>(
    'strokes_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nodeId,
    strokesJson,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'node_annotations';
  @override
  VerificationContext validateIntegrity(
    Insertable<NodeAnnotation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_nodeIdMeta);
    }
    if (data.containsKey('strokes_json')) {
      context.handle(
        _strokesJsonMeta,
        strokesJson.isAcceptableOrUnknown(
          data['strokes_json']!,
          _strokesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_strokesJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NodeAnnotation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NodeAnnotation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      )!,
      strokesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}strokes_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $NodeAnnotationsTable createAlias(String alias) {
    return $NodeAnnotationsTable(attachedDatabase, alias);
  }
}

class NodeAnnotation extends DataClass implements Insertable<NodeAnnotation> {
  final String id;
  final String nodeId;
  final String strokesJson;
  final String createdAt;
  final String? updatedAt;
  const NodeAnnotation({
    required this.id,
    required this.nodeId,
    required this.strokesJson,
    required this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['node_id'] = Variable<String>(nodeId);
    map['strokes_json'] = Variable<String>(strokesJson);
    map['created_at'] = Variable<String>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    return map;
  }

  NodeAnnotationsCompanion toCompanion(bool nullToAbsent) {
    return NodeAnnotationsCompanion(
      id: Value(id),
      nodeId: Value(nodeId),
      strokesJson: Value(strokesJson),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory NodeAnnotation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NodeAnnotation(
      id: serializer.fromJson<String>(json['id']),
      nodeId: serializer.fromJson<String>(json['nodeId']),
      strokesJson: serializer.fromJson<String>(json['strokesJson']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nodeId': serializer.toJson<String>(nodeId),
      'strokesJson': serializer.toJson<String>(strokesJson),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String?>(updatedAt),
    };
  }

  NodeAnnotation copyWith({
    String? id,
    String? nodeId,
    String? strokesJson,
    String? createdAt,
    Value<String?> updatedAt = const Value.absent(),
  }) => NodeAnnotation(
    id: id ?? this.id,
    nodeId: nodeId ?? this.nodeId,
    strokesJson: strokesJson ?? this.strokesJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  NodeAnnotation copyWithCompanion(NodeAnnotationsCompanion data) {
    return NodeAnnotation(
      id: data.id.present ? data.id.value : this.id,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      strokesJson: data.strokesJson.present
          ? data.strokesJson.value
          : this.strokesJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NodeAnnotation(')
          ..write('id: $id, ')
          ..write('nodeId: $nodeId, ')
          ..write('strokesJson: $strokesJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, nodeId, strokesJson, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NodeAnnotation &&
          other.id == this.id &&
          other.nodeId == this.nodeId &&
          other.strokesJson == this.strokesJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class NodeAnnotationsCompanion extends UpdateCompanion<NodeAnnotation> {
  final Value<String> id;
  final Value<String> nodeId;
  final Value<String> strokesJson;
  final Value<String> createdAt;
  final Value<String?> updatedAt;
  final Value<int> rowid;
  const NodeAnnotationsCompanion({
    this.id = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.strokesJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NodeAnnotationsCompanion.insert({
    required String id,
    required String nodeId,
    required String strokesJson,
    required String createdAt,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nodeId = Value(nodeId),
       strokesJson = Value(strokesJson),
       createdAt = Value(createdAt);
  static Insertable<NodeAnnotation> custom({
    Expression<String>? id,
    Expression<String>? nodeId,
    Expression<String>? strokesJson,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nodeId != null) 'node_id': nodeId,
      if (strokesJson != null) 'strokes_json': strokesJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NodeAnnotationsCompanion copyWith({
    Value<String>? id,
    Value<String>? nodeId,
    Value<String>? strokesJson,
    Value<String>? createdAt,
    Value<String?>? updatedAt,
    Value<int>? rowid,
  }) {
    return NodeAnnotationsCompanion(
      id: id ?? this.id,
      nodeId: nodeId ?? this.nodeId,
      strokesJson: strokesJson ?? this.strokesJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (strokesJson.present) {
      map['strokes_json'] = Variable<String>(strokesJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NodeAnnotationsCompanion(')
          ..write('id: $id, ')
          ..write('nodeId: $nodeId, ')
          ..write('strokesJson: $strokesJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagIndexTable extends TagIndex
    with TableInfo<$TagIndexTable, TagIndexData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagIndexTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('note'),
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
    'tag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _blockIdMeta = const VerificationMeta(
    'blockId',
  );
  @override
  late final GeneratedColumn<String> blockId = GeneratedColumn<String>(
    'block_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _textContentMeta = const VerificationMeta(
    'textContent',
  );
  @override
  late final GeneratedColumn<String> textContent = GeneratedColumn<String>(
    'text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceType,
    sourceId,
    type,
    tag,
    blockId,
    textContent,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tag_index';
  @override
  VerificationContext validateIntegrity(
    Insertable<TagIndexData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('tag')) {
      context.handle(
        _tagMeta,
        tag.isAcceptableOrUnknown(data['tag']!, _tagMeta),
      );
    } else if (isInserting) {
      context.missing(_tagMeta);
    }
    if (data.containsKey('block_id')) {
      context.handle(
        _blockIdMeta,
        blockId.isAcceptableOrUnknown(data['block_id']!, _blockIdMeta),
      );
    }
    if (data.containsKey('text')) {
      context.handle(
        _textContentMeta,
        textContent.isAcceptableOrUnknown(data['text']!, _textContentMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TagIndexData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TagIndexData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      tag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag'],
      )!,
      blockId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}block_id'],
      ),
      textContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TagIndexTable createAlias(String alias) {
    return $TagIndexTable(attachedDatabase, alias);
  }
}

class TagIndexData extends DataClass implements Insertable<TagIndexData> {
  final String id;
  final String sourceType;
  final String sourceId;
  final String type;
  final String tag;
  final String? blockId;
  final String? textContent;
  final String createdAt;
  const TagIndexData({
    required this.id,
    required this.sourceType,
    required this.sourceId,
    required this.type,
    required this.tag,
    this.blockId,
    this.textContent,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_type'] = Variable<String>(sourceType);
    map['source_id'] = Variable<String>(sourceId);
    map['type'] = Variable<String>(type);
    map['tag'] = Variable<String>(tag);
    if (!nullToAbsent || blockId != null) {
      map['block_id'] = Variable<String>(blockId);
    }
    if (!nullToAbsent || textContent != null) {
      map['text'] = Variable<String>(textContent);
    }
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  TagIndexCompanion toCompanion(bool nullToAbsent) {
    return TagIndexCompanion(
      id: Value(id),
      sourceType: Value(sourceType),
      sourceId: Value(sourceId),
      type: Value(type),
      tag: Value(tag),
      blockId: blockId == null && nullToAbsent
          ? const Value.absent()
          : Value(blockId),
      textContent: textContent == null && nullToAbsent
          ? const Value.absent()
          : Value(textContent),
      createdAt: Value(createdAt),
    );
  }

  factory TagIndexData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TagIndexData(
      id: serializer.fromJson<String>(json['id']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      type: serializer.fromJson<String>(json['type']),
      tag: serializer.fromJson<String>(json['tag']),
      blockId: serializer.fromJson<String?>(json['blockId']),
      textContent: serializer.fromJson<String?>(json['textContent']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceType': serializer.toJson<String>(sourceType),
      'sourceId': serializer.toJson<String>(sourceId),
      'type': serializer.toJson<String>(type),
      'tag': serializer.toJson<String>(tag),
      'blockId': serializer.toJson<String?>(blockId),
      'textContent': serializer.toJson<String?>(textContent),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  TagIndexData copyWith({
    String? id,
    String? sourceType,
    String? sourceId,
    String? type,
    String? tag,
    Value<String?> blockId = const Value.absent(),
    Value<String?> textContent = const Value.absent(),
    String? createdAt,
  }) => TagIndexData(
    id: id ?? this.id,
    sourceType: sourceType ?? this.sourceType,
    sourceId: sourceId ?? this.sourceId,
    type: type ?? this.type,
    tag: tag ?? this.tag,
    blockId: blockId.present ? blockId.value : this.blockId,
    textContent: textContent.present ? textContent.value : this.textContent,
    createdAt: createdAt ?? this.createdAt,
  );
  TagIndexData copyWithCompanion(TagIndexCompanion data) {
    return TagIndexData(
      id: data.id.present ? data.id.value : this.id,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      type: data.type.present ? data.type.value : this.type,
      tag: data.tag.present ? data.tag.value : this.tag,
      blockId: data.blockId.present ? data.blockId.value : this.blockId,
      textContent: data.textContent.present
          ? data.textContent.value
          : this.textContent,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TagIndexData(')
          ..write('id: $id, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceId: $sourceId, ')
          ..write('type: $type, ')
          ..write('tag: $tag, ')
          ..write('blockId: $blockId, ')
          ..write('textContent: $textContent, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceType,
    sourceId,
    type,
    tag,
    blockId,
    textContent,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TagIndexData &&
          other.id == this.id &&
          other.sourceType == this.sourceType &&
          other.sourceId == this.sourceId &&
          other.type == this.type &&
          other.tag == this.tag &&
          other.blockId == this.blockId &&
          other.textContent == this.textContent &&
          other.createdAt == this.createdAt);
}

class TagIndexCompanion extends UpdateCompanion<TagIndexData> {
  final Value<String> id;
  final Value<String> sourceType;
  final Value<String> sourceId;
  final Value<String> type;
  final Value<String> tag;
  final Value<String?> blockId;
  final Value<String?> textContent;
  final Value<String> createdAt;
  final Value<int> rowid;
  const TagIndexCompanion({
    this.id = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.type = const Value.absent(),
    this.tag = const Value.absent(),
    this.blockId = const Value.absent(),
    this.textContent = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagIndexCompanion.insert({
    required String id,
    this.sourceType = const Value.absent(),
    required String sourceId,
    required String type,
    required String tag,
    this.blockId = const Value.absent(),
    this.textContent = const Value.absent(),
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourceId = Value(sourceId),
       type = Value(type),
       tag = Value(tag),
       createdAt = Value(createdAt);
  static Insertable<TagIndexData> custom({
    Expression<String>? id,
    Expression<String>? sourceType,
    Expression<String>? sourceId,
    Expression<String>? type,
    Expression<String>? tag,
    Expression<String>? blockId,
    Expression<String>? textContent,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceType != null) 'source_type': sourceType,
      if (sourceId != null) 'source_id': sourceId,
      if (type != null) 'type': type,
      if (tag != null) 'tag': tag,
      if (blockId != null) 'block_id': blockId,
      if (textContent != null) 'text': textContent,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagIndexCompanion copyWith({
    Value<String>? id,
    Value<String>? sourceType,
    Value<String>? sourceId,
    Value<String>? type,
    Value<String>? tag,
    Value<String?>? blockId,
    Value<String?>? textContent,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return TagIndexCompanion(
      id: id ?? this.id,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      type: type ?? this.type,
      tag: tag ?? this.tag,
      blockId: blockId ?? this.blockId,
      textContent: textContent ?? this.textContent,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    if (blockId.present) {
      map['block_id'] = Variable<String>(blockId.value);
    }
    if (textContent.present) {
      map['text'] = Variable<String>(textContent.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagIndexCompanion(')
          ..write('id: $id, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceId: $sourceId, ')
          ..write('type: $type, ')
          ..write('tag: $tag, ')
          ..write('blockId: $blockId, ')
          ..write('textContent: $textContent, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SearchIndexTable extends SearchIndex
    with TableInfo<$SearchIndexTable, SearchIndexData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SearchIndexTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subIdMeta = const VerificationMeta('subId');
  @override
  late final GeneratedColumn<String> subId = GeneratedColumn<String>(
    'sub_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _searchTextMeta = const VerificationMeta(
    'searchText',
  );
  @override
  late final GeneratedColumn<String> searchText = GeneratedColumn<String>(
    'search_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawTextMeta = const VerificationMeta(
    'rawText',
  );
  @override
  late final GeneratedColumn<String> rawText = GeneratedColumn<String>(
    'raw_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceType,
    sourceId,
    subId,
    location,
    kind,
    searchText,
    rawText,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'search_index';
  @override
  VerificationContext validateIntegrity(
    Insertable<SearchIndexData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceTypeMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('sub_id')) {
      context.handle(
        _subIdMeta,
        subId.isAcceptableOrUnknown(data['sub_id']!, _subIdMeta),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('search_text')) {
      context.handle(
        _searchTextMeta,
        searchText.isAcceptableOrUnknown(data['search_text']!, _searchTextMeta),
      );
    } else if (isInserting) {
      context.missing(_searchTextMeta);
    }
    if (data.containsKey('raw_text')) {
      context.handle(
        _rawTextMeta,
        rawText.isAcceptableOrUnknown(data['raw_text']!, _rawTextMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SearchIndexData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SearchIndexData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      subId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sub_id'],
      ),
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      searchText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search_text'],
      )!,
      rawText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_text'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SearchIndexTable createAlias(String alias) {
    return $SearchIndexTable(attachedDatabase, alias);
  }
}

class SearchIndexData extends DataClass implements Insertable<SearchIndexData> {
  final String id;
  final String sourceType;
  final String sourceId;
  final String? subId;
  final String? location;
  final String kind;
  final String searchText;
  final String? rawText;
  final String createdAt;
  const SearchIndexData({
    required this.id,
    required this.sourceType,
    required this.sourceId,
    this.subId,
    this.location,
    required this.kind,
    required this.searchText,
    this.rawText,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_type'] = Variable<String>(sourceType);
    map['source_id'] = Variable<String>(sourceId);
    if (!nullToAbsent || subId != null) {
      map['sub_id'] = Variable<String>(subId);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    map['kind'] = Variable<String>(kind);
    map['search_text'] = Variable<String>(searchText);
    if (!nullToAbsent || rawText != null) {
      map['raw_text'] = Variable<String>(rawText);
    }
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  SearchIndexCompanion toCompanion(bool nullToAbsent) {
    return SearchIndexCompanion(
      id: Value(id),
      sourceType: Value(sourceType),
      sourceId: Value(sourceId),
      subId: subId == null && nullToAbsent
          ? const Value.absent()
          : Value(subId),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      kind: Value(kind),
      searchText: Value(searchText),
      rawText: rawText == null && nullToAbsent
          ? const Value.absent()
          : Value(rawText),
      createdAt: Value(createdAt),
    );
  }

  factory SearchIndexData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SearchIndexData(
      id: serializer.fromJson<String>(json['id']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      subId: serializer.fromJson<String?>(json['subId']),
      location: serializer.fromJson<String?>(json['location']),
      kind: serializer.fromJson<String>(json['kind']),
      searchText: serializer.fromJson<String>(json['searchText']),
      rawText: serializer.fromJson<String?>(json['rawText']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceType': serializer.toJson<String>(sourceType),
      'sourceId': serializer.toJson<String>(sourceId),
      'subId': serializer.toJson<String?>(subId),
      'location': serializer.toJson<String?>(location),
      'kind': serializer.toJson<String>(kind),
      'searchText': serializer.toJson<String>(searchText),
      'rawText': serializer.toJson<String?>(rawText),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  SearchIndexData copyWith({
    String? id,
    String? sourceType,
    String? sourceId,
    Value<String?> subId = const Value.absent(),
    Value<String?> location = const Value.absent(),
    String? kind,
    String? searchText,
    Value<String?> rawText = const Value.absent(),
    String? createdAt,
  }) => SearchIndexData(
    id: id ?? this.id,
    sourceType: sourceType ?? this.sourceType,
    sourceId: sourceId ?? this.sourceId,
    subId: subId.present ? subId.value : this.subId,
    location: location.present ? location.value : this.location,
    kind: kind ?? this.kind,
    searchText: searchText ?? this.searchText,
    rawText: rawText.present ? rawText.value : this.rawText,
    createdAt: createdAt ?? this.createdAt,
  );
  SearchIndexData copyWithCompanion(SearchIndexCompanion data) {
    return SearchIndexData(
      id: data.id.present ? data.id.value : this.id,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      subId: data.subId.present ? data.subId.value : this.subId,
      location: data.location.present ? data.location.value : this.location,
      kind: data.kind.present ? data.kind.value : this.kind,
      searchText: data.searchText.present
          ? data.searchText.value
          : this.searchText,
      rawText: data.rawText.present ? data.rawText.value : this.rawText,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SearchIndexData(')
          ..write('id: $id, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceId: $sourceId, ')
          ..write('subId: $subId, ')
          ..write('location: $location, ')
          ..write('kind: $kind, ')
          ..write('searchText: $searchText, ')
          ..write('rawText: $rawText, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceType,
    sourceId,
    subId,
    location,
    kind,
    searchText,
    rawText,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchIndexData &&
          other.id == this.id &&
          other.sourceType == this.sourceType &&
          other.sourceId == this.sourceId &&
          other.subId == this.subId &&
          other.location == this.location &&
          other.kind == this.kind &&
          other.searchText == this.searchText &&
          other.rawText == this.rawText &&
          other.createdAt == this.createdAt);
}

class SearchIndexCompanion extends UpdateCompanion<SearchIndexData> {
  final Value<String> id;
  final Value<String> sourceType;
  final Value<String> sourceId;
  final Value<String?> subId;
  final Value<String?> location;
  final Value<String> kind;
  final Value<String> searchText;
  final Value<String?> rawText;
  final Value<String> createdAt;
  final Value<int> rowid;
  const SearchIndexCompanion({
    this.id = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.subId = const Value.absent(),
    this.location = const Value.absent(),
    this.kind = const Value.absent(),
    this.searchText = const Value.absent(),
    this.rawText = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SearchIndexCompanion.insert({
    required String id,
    required String sourceType,
    required String sourceId,
    this.subId = const Value.absent(),
    this.location = const Value.absent(),
    required String kind,
    required String searchText,
    this.rawText = const Value.absent(),
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourceType = Value(sourceType),
       sourceId = Value(sourceId),
       kind = Value(kind),
       searchText = Value(searchText),
       createdAt = Value(createdAt);
  static Insertable<SearchIndexData> custom({
    Expression<String>? id,
    Expression<String>? sourceType,
    Expression<String>? sourceId,
    Expression<String>? subId,
    Expression<String>? location,
    Expression<String>? kind,
    Expression<String>? searchText,
    Expression<String>? rawText,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceType != null) 'source_type': sourceType,
      if (sourceId != null) 'source_id': sourceId,
      if (subId != null) 'sub_id': subId,
      if (location != null) 'location': location,
      if (kind != null) 'kind': kind,
      if (searchText != null) 'search_text': searchText,
      if (rawText != null) 'raw_text': rawText,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SearchIndexCompanion copyWith({
    Value<String>? id,
    Value<String>? sourceType,
    Value<String>? sourceId,
    Value<String?>? subId,
    Value<String?>? location,
    Value<String>? kind,
    Value<String>? searchText,
    Value<String?>? rawText,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return SearchIndexCompanion(
      id: id ?? this.id,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      subId: subId ?? this.subId,
      location: location ?? this.location,
      kind: kind ?? this.kind,
      searchText: searchText ?? this.searchText,
      rawText: rawText ?? this.rawText,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (subId.present) {
      map['sub_id'] = Variable<String>(subId.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (searchText.present) {
      map['search_text'] = Variable<String>(searchText.value);
    }
    if (rawText.present) {
      map['raw_text'] = Variable<String>(rawText.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SearchIndexCompanion(')
          ..write('id: $id, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceId: $sourceId, ')
          ..write('subId: $subId, ')
          ..write('location: $location, ')
          ..write('kind: $kind, ')
          ..write('searchText: $searchText, ')
          ..write('rawText: $rawText, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WritingSessionsTable extends WritingSessions
    with TableInfo<$WritingSessionsTable, WritingSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WritingSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
    'note_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startAtMeta = const VerificationMeta(
    'startAt',
  );
  @override
  late final GeneratedColumn<String> startAt = GeneratedColumn<String>(
    'start_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endAtMeta = const VerificationMeta('endAt');
  @override
  late final GeneratedColumn<String> endAt = GeneratedColumn<String>(
    'end_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordCountMeta = const VerificationMeta(
    'wordCount',
  );
  @override
  late final GeneratedColumn<int> wordCount = GeneratedColumn<int>(
    'word_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _pausedSecondsMeta = const VerificationMeta(
    'pausedSeconds',
  );
  @override
  late final GeneratedColumn<int> pausedSeconds = GeneratedColumn<int>(
    'paused_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    noteId,
    startAt,
    endAt,
    wordCount,
    pausedSeconds,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'writing_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<WritingSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('note_id')) {
      context.handle(
        _noteIdMeta,
        noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('start_at')) {
      context.handle(
        _startAtMeta,
        startAt.isAcceptableOrUnknown(data['start_at']!, _startAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startAtMeta);
    }
    if (data.containsKey('end_at')) {
      context.handle(
        _endAtMeta,
        endAt.isAcceptableOrUnknown(data['end_at']!, _endAtMeta),
      );
    } else if (isInserting) {
      context.missing(_endAtMeta);
    }
    if (data.containsKey('word_count')) {
      context.handle(
        _wordCountMeta,
        wordCount.isAcceptableOrUnknown(data['word_count']!, _wordCountMeta),
      );
    }
    if (data.containsKey('paused_seconds')) {
      context.handle(
        _pausedSecondsMeta,
        pausedSeconds.isAcceptableOrUnknown(
          data['paused_seconds']!,
          _pausedSecondsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WritingSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WritingSessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      noteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_id'],
      )!,
      startAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_at'],
      )!,
      endAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_at'],
      )!,
      wordCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_count'],
      )!,
      pausedSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paused_seconds'],
      )!,
    );
  }

  @override
  $WritingSessionsTable createAlias(String alias) {
    return $WritingSessionsTable(attachedDatabase, alias);
  }
}

class WritingSessionRow extends DataClass
    implements Insertable<WritingSessionRow> {
  final String id;
  final String noteId;
  final String startAt;
  final String endAt;
  final int wordCount;
  final int pausedSeconds;
  const WritingSessionRow({
    required this.id,
    required this.noteId,
    required this.startAt,
    required this.endAt,
    required this.wordCount,
    required this.pausedSeconds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['note_id'] = Variable<String>(noteId);
    map['start_at'] = Variable<String>(startAt);
    map['end_at'] = Variable<String>(endAt);
    map['word_count'] = Variable<int>(wordCount);
    map['paused_seconds'] = Variable<int>(pausedSeconds);
    return map;
  }

  WritingSessionsCompanion toCompanion(bool nullToAbsent) {
    return WritingSessionsCompanion(
      id: Value(id),
      noteId: Value(noteId),
      startAt: Value(startAt),
      endAt: Value(endAt),
      wordCount: Value(wordCount),
      pausedSeconds: Value(pausedSeconds),
    );
  }

  factory WritingSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WritingSessionRow(
      id: serializer.fromJson<String>(json['id']),
      noteId: serializer.fromJson<String>(json['noteId']),
      startAt: serializer.fromJson<String>(json['startAt']),
      endAt: serializer.fromJson<String>(json['endAt']),
      wordCount: serializer.fromJson<int>(json['wordCount']),
      pausedSeconds: serializer.fromJson<int>(json['pausedSeconds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'noteId': serializer.toJson<String>(noteId),
      'startAt': serializer.toJson<String>(startAt),
      'endAt': serializer.toJson<String>(endAt),
      'wordCount': serializer.toJson<int>(wordCount),
      'pausedSeconds': serializer.toJson<int>(pausedSeconds),
    };
  }

  WritingSessionRow copyWith({
    String? id,
    String? noteId,
    String? startAt,
    String? endAt,
    int? wordCount,
    int? pausedSeconds,
  }) => WritingSessionRow(
    id: id ?? this.id,
    noteId: noteId ?? this.noteId,
    startAt: startAt ?? this.startAt,
    endAt: endAt ?? this.endAt,
    wordCount: wordCount ?? this.wordCount,
    pausedSeconds: pausedSeconds ?? this.pausedSeconds,
  );
  WritingSessionRow copyWithCompanion(WritingSessionsCompanion data) {
    return WritingSessionRow(
      id: data.id.present ? data.id.value : this.id,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      startAt: data.startAt.present ? data.startAt.value : this.startAt,
      endAt: data.endAt.present ? data.endAt.value : this.endAt,
      wordCount: data.wordCount.present ? data.wordCount.value : this.wordCount,
      pausedSeconds: data.pausedSeconds.present
          ? data.pausedSeconds.value
          : this.pausedSeconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WritingSessionRow(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('wordCount: $wordCount, ')
          ..write('pausedSeconds: $pausedSeconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, noteId, startAt, endAt, wordCount, pausedSeconds);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WritingSessionRow &&
          other.id == this.id &&
          other.noteId == this.noteId &&
          other.startAt == this.startAt &&
          other.endAt == this.endAt &&
          other.wordCount == this.wordCount &&
          other.pausedSeconds == this.pausedSeconds);
}

class WritingSessionsCompanion extends UpdateCompanion<WritingSessionRow> {
  final Value<String> id;
  final Value<String> noteId;
  final Value<String> startAt;
  final Value<String> endAt;
  final Value<int> wordCount;
  final Value<int> pausedSeconds;
  final Value<int> rowid;
  const WritingSessionsCompanion({
    this.id = const Value.absent(),
    this.noteId = const Value.absent(),
    this.startAt = const Value.absent(),
    this.endAt = const Value.absent(),
    this.wordCount = const Value.absent(),
    this.pausedSeconds = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WritingSessionsCompanion.insert({
    required String id,
    required String noteId,
    required String startAt,
    required String endAt,
    this.wordCount = const Value.absent(),
    this.pausedSeconds = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       noteId = Value(noteId),
       startAt = Value(startAt),
       endAt = Value(endAt);
  static Insertable<WritingSessionRow> custom({
    Expression<String>? id,
    Expression<String>? noteId,
    Expression<String>? startAt,
    Expression<String>? endAt,
    Expression<int>? wordCount,
    Expression<int>? pausedSeconds,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (noteId != null) 'note_id': noteId,
      if (startAt != null) 'start_at': startAt,
      if (endAt != null) 'end_at': endAt,
      if (wordCount != null) 'word_count': wordCount,
      if (pausedSeconds != null) 'paused_seconds': pausedSeconds,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WritingSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? noteId,
    Value<String>? startAt,
    Value<String>? endAt,
    Value<int>? wordCount,
    Value<int>? pausedSeconds,
    Value<int>? rowid,
  }) {
    return WritingSessionsCompanion(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      wordCount: wordCount ?? this.wordCount,
      pausedSeconds: pausedSeconds ?? this.pausedSeconds,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (startAt.present) {
      map['start_at'] = Variable<String>(startAt.value);
    }
    if (endAt.present) {
      map['end_at'] = Variable<String>(endAt.value);
    }
    if (wordCount.present) {
      map['word_count'] = Variable<int>(wordCount.value);
    }
    if (pausedSeconds.present) {
      map['paused_seconds'] = Variable<int>(pausedSeconds.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WritingSessionsCompanion(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('wordCount: $wordCount, ')
          ..write('pausedSeconds: $pausedSeconds, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FocusSessionsTable extends FocusSessions
    with TableInfo<$FocusSessionsTable, FocusSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FocusSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startAtMeta = const VerificationMeta(
    'startAt',
  );
  @override
  late final GeneratedColumn<String> startAt = GeneratedColumn<String>(
    'start_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minutesMeta = const VerificationMeta(
    'minutes',
  );
  @override
  late final GeneratedColumn<int> minutes = GeneratedColumn<int>(
    'minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, startAt, minutes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'focus_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<FocusSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('start_at')) {
      context.handle(
        _startAtMeta,
        startAt.isAcceptableOrUnknown(data['start_at']!, _startAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startAtMeta);
    }
    if (data.containsKey('minutes')) {
      context.handle(
        _minutesMeta,
        minutes.isAcceptableOrUnknown(data['minutes']!, _minutesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FocusSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FocusSessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      startAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_at'],
      )!,
      minutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minutes'],
      )!,
    );
  }

  @override
  $FocusSessionsTable createAlias(String alias) {
    return $FocusSessionsTable(attachedDatabase, alias);
  }
}

class FocusSessionRow extends DataClass implements Insertable<FocusSessionRow> {
  final String id;
  final String startAt;
  final int minutes;
  const FocusSessionRow({
    required this.id,
    required this.startAt,
    required this.minutes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['start_at'] = Variable<String>(startAt);
    map['minutes'] = Variable<int>(minutes);
    return map;
  }

  FocusSessionsCompanion toCompanion(bool nullToAbsent) {
    return FocusSessionsCompanion(
      id: Value(id),
      startAt: Value(startAt),
      minutes: Value(minutes),
    );
  }

  factory FocusSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FocusSessionRow(
      id: serializer.fromJson<String>(json['id']),
      startAt: serializer.fromJson<String>(json['startAt']),
      minutes: serializer.fromJson<int>(json['minutes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'startAt': serializer.toJson<String>(startAt),
      'minutes': serializer.toJson<int>(minutes),
    };
  }

  FocusSessionRow copyWith({String? id, String? startAt, int? minutes}) =>
      FocusSessionRow(
        id: id ?? this.id,
        startAt: startAt ?? this.startAt,
        minutes: minutes ?? this.minutes,
      );
  FocusSessionRow copyWithCompanion(FocusSessionsCompanion data) {
    return FocusSessionRow(
      id: data.id.present ? data.id.value : this.id,
      startAt: data.startAt.present ? data.startAt.value : this.startAt,
      minutes: data.minutes.present ? data.minutes.value : this.minutes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FocusSessionRow(')
          ..write('id: $id, ')
          ..write('startAt: $startAt, ')
          ..write('minutes: $minutes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, startAt, minutes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FocusSessionRow &&
          other.id == this.id &&
          other.startAt == this.startAt &&
          other.minutes == this.minutes);
}

class FocusSessionsCompanion extends UpdateCompanion<FocusSessionRow> {
  final Value<String> id;
  final Value<String> startAt;
  final Value<int> minutes;
  final Value<int> rowid;
  const FocusSessionsCompanion({
    this.id = const Value.absent(),
    this.startAt = const Value.absent(),
    this.minutes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FocusSessionsCompanion.insert({
    required String id,
    required String startAt,
    this.minutes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       startAt = Value(startAt);
  static Insertable<FocusSessionRow> custom({
    Expression<String>? id,
    Expression<String>? startAt,
    Expression<int>? minutes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startAt != null) 'start_at': startAt,
      if (minutes != null) 'minutes': minutes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FocusSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? startAt,
    Value<int>? minutes,
    Value<int>? rowid,
  }) {
    return FocusSessionsCompanion(
      id: id ?? this.id,
      startAt: startAt ?? this.startAt,
      minutes: minutes ?? this.minutes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (startAt.present) {
      map['start_at'] = Variable<String>(startAt.value);
    }
    if (minutes.present) {
      map['minutes'] = Variable<int>(minutes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FocusSessionsCompanion(')
          ..write('id: $id, ')
          ..write('startAt: $startAt, ')
          ..write('minutes: $minutes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadingStatsTable extends ReadingStats
    with TableInfo<$ReadingStatsTable, ReadingStat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingStatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minutesMeta = const VerificationMeta(
    'minutes',
  );
  @override
  late final GeneratedColumn<int> minutes = GeneratedColumn<int>(
    'minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _pagesMeta = const VerificationMeta('pages');
  @override
  late final GeneratedColumn<int> pages = GeneratedColumn<int>(
    'pages',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, date, minutes, pages, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_stats';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingStat> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('minutes')) {
      context.handle(
        _minutesMeta,
        minutes.isAcceptableOrUnknown(data['minutes']!, _minutesMeta),
      );
    }
    if (data.containsKey('pages')) {
      context.handle(
        _pagesMeta,
        pages.isAcceptableOrUnknown(data['pages']!, _pagesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadingStat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingStat(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      minutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minutes'],
      )!,
      pages: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pages'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ReadingStatsTable createAlias(String alias) {
    return $ReadingStatsTable(attachedDatabase, alias);
  }
}

class ReadingStat extends DataClass implements Insertable<ReadingStat> {
  final String id;
  final String date;
  final int minutes;
  final int pages;
  final String createdAt;
  const ReadingStat({
    required this.id,
    required this.date,
    required this.minutes,
    required this.pages,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<String>(date);
    map['minutes'] = Variable<int>(minutes);
    map['pages'] = Variable<int>(pages);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  ReadingStatsCompanion toCompanion(bool nullToAbsent) {
    return ReadingStatsCompanion(
      id: Value(id),
      date: Value(date),
      minutes: Value(minutes),
      pages: Value(pages),
      createdAt: Value(createdAt),
    );
  }

  factory ReadingStat.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingStat(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      minutes: serializer.fromJson<int>(json['minutes']),
      pages: serializer.fromJson<int>(json['pages']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<String>(date),
      'minutes': serializer.toJson<int>(minutes),
      'pages': serializer.toJson<int>(pages),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  ReadingStat copyWith({
    String? id,
    String? date,
    int? minutes,
    int? pages,
    String? createdAt,
  }) => ReadingStat(
    id: id ?? this.id,
    date: date ?? this.date,
    minutes: minutes ?? this.minutes,
    pages: pages ?? this.pages,
    createdAt: createdAt ?? this.createdAt,
  );
  ReadingStat copyWithCompanion(ReadingStatsCompanion data) {
    return ReadingStat(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      minutes: data.minutes.present ? data.minutes.value : this.minutes,
      pages: data.pages.present ? data.pages.value : this.pages,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingStat(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('minutes: $minutes, ')
          ..write('pages: $pages, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, minutes, pages, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingStat &&
          other.id == this.id &&
          other.date == this.date &&
          other.minutes == this.minutes &&
          other.pages == this.pages &&
          other.createdAt == this.createdAt);
}

class ReadingStatsCompanion extends UpdateCompanion<ReadingStat> {
  final Value<String> id;
  final Value<String> date;
  final Value<int> minutes;
  final Value<int> pages;
  final Value<String> createdAt;
  final Value<int> rowid;
  const ReadingStatsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.minutes = const Value.absent(),
    this.pages = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadingStatsCompanion.insert({
    required String id,
    required String date,
    this.minutes = const Value.absent(),
    this.pages = const Value.absent(),
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       date = Value(date),
       createdAt = Value(createdAt);
  static Insertable<ReadingStat> custom({
    Expression<String>? id,
    Expression<String>? date,
    Expression<int>? minutes,
    Expression<int>? pages,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (minutes != null) 'minutes': minutes,
      if (pages != null) 'pages': pages,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadingStatsCompanion copyWith({
    Value<String>? id,
    Value<String>? date,
    Value<int>? minutes,
    Value<int>? pages,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return ReadingStatsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      minutes: minutes ?? this.minutes,
      pages: pages ?? this.pages,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (minutes.present) {
      map['minutes'] = Variable<int>(minutes.value);
    }
    if (pages.present) {
      map['pages'] = Variable<int>(pages.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingStatsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('minutes: $minutes, ')
          ..write('pages: $pages, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CardsTable extends Cards with TableInfo<$CardsTable, CardsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cardTypeMeta = const VerificationMeta(
    'cardType',
  );
  @override
  late final GeneratedColumn<String> cardType = GeneratedColumn<String>(
    'card_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sourceTitleMeta = const VerificationMeta(
    'sourceTitle',
  );
  @override
  late final GeneratedColumn<String> sourceTitle = GeneratedColumn<String>(
    'source_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('atomic'),
  );
  static const VerificationMeta _importanceMeta = const VerificationMeta(
    'importance',
  );
  @override
  late final GeneratedColumn<String> importance = GeneratedColumn<String>(
    'importance',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('medium'),
  );
  static const VerificationMeta _frontMeta = const VerificationMeta('front');
  @override
  late final GeneratedColumn<String> front = GeneratedColumn<String>(
    'front',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _backMeta = const VerificationMeta('back');
  @override
  late final GeneratedColumn<String> back = GeneratedColumn<String>(
    'back',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _indexTitleMeta = const VerificationMeta(
    'indexTitle',
  );
  @override
  late final GeneratedColumn<String> indexTitle = GeneratedColumn<String>(
    'index_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _highlightMeta = const VerificationMeta(
    'highlight',
  );
  @override
  late final GeneratedColumn<String> highlight = GeneratedColumn<String>(
    'highlight',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _anchorMeta = const VerificationMeta('anchor');
  @override
  late final GeneratedColumn<String> anchor = GeneratedColumn<String>(
    'anchor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _questionMeta = const VerificationMeta(
    'question',
  );
  @override
  late final GeneratedColumn<String> question = GeneratedColumn<String>(
    'question',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _answerMeta = const VerificationMeta('answer');
  @override
  late final GeneratedColumn<String> answer = GeneratedColumn<String>(
    'answer',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fillQuestionMeta = const VerificationMeta(
    'fillQuestion',
  );
  @override
  late final GeneratedColumn<String> fillQuestion = GeneratedColumn<String>(
    'fill_question',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fillAnswerMeta = const VerificationMeta(
    'fillAnswer',
  );
  @override
  late final GeneratedColumn<String> fillAnswer = GeneratedColumn<String>(
    'fill_answer',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _choiceQuestionMeta = const VerificationMeta(
    'choiceQuestion',
  );
  @override
  late final GeneratedColumn<String> choiceQuestion = GeneratedColumn<String>(
    'choice_question',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _choiceOptionsMeta = const VerificationMeta(
    'choiceOptions',
  );
  @override
  late final GeneratedColumn<String> choiceOptions = GeneratedColumn<String>(
    'choice_options',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _choiceCorrectIndexMeta =
      const VerificationMeta('choiceCorrectIndex');
  @override
  late final GeneratedColumn<int> choiceCorrectIndex = GeneratedColumn<int>(
    'choice_correct_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tfStatementMeta = const VerificationMeta(
    'tfStatement',
  );
  @override
  late final GeneratedColumn<String> tfStatement = GeneratedColumn<String>(
    'tf_statement',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tfIsTrueMeta = const VerificationMeta(
    'tfIsTrue',
  );
  @override
  late final GeneratedColumn<bool> tfIsTrue = GeneratedColumn<bool>(
    'tf_is_true',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("tf_is_true" IN (0, 1))',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _lastReviewDateMeta = const VerificationMeta(
    'lastReviewDate',
  );
  @override
  late final GeneratedColumn<String> lastReviewDate = GeneratedColumn<String>(
    'last_review_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextReviewDateMeta = const VerificationMeta(
    'nextReviewDate',
  );
  @override
  late final GeneratedColumn<String> nextReviewDate = GeneratedColumn<String>(
    'next_review_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _memoryLevelMeta = const VerificationMeta(
    'memoryLevel',
  );
  @override
  late final GeneratedColumn<double> memoryLevel = GeneratedColumn<double>(
    'memory_level',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.5),
  );
  static const VerificationMeta _relatedIdsMeta = const VerificationMeta(
    'relatedIds',
  );
  @override
  late final GeneratedColumn<String> relatedIds = GeneratedColumn<String>(
    'related_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _stageMeta = const VerificationMeta('stage');
  @override
  late final GeneratedColumn<int> stage = GeneratedColumn<int>(
    'stage',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _masteredMeta = const VerificationMeta(
    'mastered',
  );
  @override
  late final GeneratedColumn<bool> mastered = GeneratedColumn<bool>(
    'mastered',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("mastered" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _totalReviewsMeta = const VerificationMeta(
    'totalReviews',
  );
  @override
  late final GeneratedColumn<int> totalReviews = GeneratedColumn<int>(
    'total_reviews',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _failedCountMeta = const VerificationMeta(
    'failedCount',
  );
  @override
  late final GeneratedColumn<int> failedCount = GeneratedColumn<int>(
    'failed_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _usageCountMeta = const VerificationMeta(
    'usageCount',
  );
  @override
  late final GeneratedColumn<int> usageCount = GeneratedColumn<int>(
    'usage_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cardType,
    sourceType,
    sourceId,
    sourceTitle,
    tags,
    kind,
    importance,
    front,
    back,
    indexTitle,
    author,
    highlight,
    anchor,
    question,
    answer,
    fillQuestion,
    fillAnswer,
    choiceQuestion,
    choiceOptions,
    choiceCorrectIndex,
    tfStatement,
    tfIsTrue,
    createdAt,
    updatedAt,
    lastReviewDate,
    nextReviewDate,
    memoryLevel,
    relatedIds,
    stage,
    mastered,
    totalReviews,
    failedCount,
    usageCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<CardsData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('card_type')) {
      context.handle(
        _cardTypeMeta,
        cardType.isAcceptableOrUnknown(data['card_type']!, _cardTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_cardTypeMeta);
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('source_title')) {
      context.handle(
        _sourceTitleMeta,
        sourceTitle.isAcceptableOrUnknown(
          data['source_title']!,
          _sourceTitleMeta,
        ),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('importance')) {
      context.handle(
        _importanceMeta,
        importance.isAcceptableOrUnknown(data['importance']!, _importanceMeta),
      );
    }
    if (data.containsKey('front')) {
      context.handle(
        _frontMeta,
        front.isAcceptableOrUnknown(data['front']!, _frontMeta),
      );
    }
    if (data.containsKey('back')) {
      context.handle(
        _backMeta,
        back.isAcceptableOrUnknown(data['back']!, _backMeta),
      );
    }
    if (data.containsKey('index_title')) {
      context.handle(
        _indexTitleMeta,
        indexTitle.isAcceptableOrUnknown(data['index_title']!, _indexTitleMeta),
      );
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('highlight')) {
      context.handle(
        _highlightMeta,
        highlight.isAcceptableOrUnknown(data['highlight']!, _highlightMeta),
      );
    }
    if (data.containsKey('anchor')) {
      context.handle(
        _anchorMeta,
        anchor.isAcceptableOrUnknown(data['anchor']!, _anchorMeta),
      );
    }
    if (data.containsKey('question')) {
      context.handle(
        _questionMeta,
        question.isAcceptableOrUnknown(data['question']!, _questionMeta),
      );
    }
    if (data.containsKey('answer')) {
      context.handle(
        _answerMeta,
        answer.isAcceptableOrUnknown(data['answer']!, _answerMeta),
      );
    }
    if (data.containsKey('fill_question')) {
      context.handle(
        _fillQuestionMeta,
        fillQuestion.isAcceptableOrUnknown(
          data['fill_question']!,
          _fillQuestionMeta,
        ),
      );
    }
    if (data.containsKey('fill_answer')) {
      context.handle(
        _fillAnswerMeta,
        fillAnswer.isAcceptableOrUnknown(data['fill_answer']!, _fillAnswerMeta),
      );
    }
    if (data.containsKey('choice_question')) {
      context.handle(
        _choiceQuestionMeta,
        choiceQuestion.isAcceptableOrUnknown(
          data['choice_question']!,
          _choiceQuestionMeta,
        ),
      );
    }
    if (data.containsKey('choice_options')) {
      context.handle(
        _choiceOptionsMeta,
        choiceOptions.isAcceptableOrUnknown(
          data['choice_options']!,
          _choiceOptionsMeta,
        ),
      );
    }
    if (data.containsKey('choice_correct_index')) {
      context.handle(
        _choiceCorrectIndexMeta,
        choiceCorrectIndex.isAcceptableOrUnknown(
          data['choice_correct_index']!,
          _choiceCorrectIndexMeta,
        ),
      );
    }
    if (data.containsKey('tf_statement')) {
      context.handle(
        _tfStatementMeta,
        tfStatement.isAcceptableOrUnknown(
          data['tf_statement']!,
          _tfStatementMeta,
        ),
      );
    }
    if (data.containsKey('tf_is_true')) {
      context.handle(
        _tfIsTrueMeta,
        tfIsTrue.isAcceptableOrUnknown(data['tf_is_true']!, _tfIsTrueMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('last_review_date')) {
      context.handle(
        _lastReviewDateMeta,
        lastReviewDate.isAcceptableOrUnknown(
          data['last_review_date']!,
          _lastReviewDateMeta,
        ),
      );
    }
    if (data.containsKey('next_review_date')) {
      context.handle(
        _nextReviewDateMeta,
        nextReviewDate.isAcceptableOrUnknown(
          data['next_review_date']!,
          _nextReviewDateMeta,
        ),
      );
    }
    if (data.containsKey('memory_level')) {
      context.handle(
        _memoryLevelMeta,
        memoryLevel.isAcceptableOrUnknown(
          data['memory_level']!,
          _memoryLevelMeta,
        ),
      );
    }
    if (data.containsKey('related_ids')) {
      context.handle(
        _relatedIdsMeta,
        relatedIds.isAcceptableOrUnknown(data['related_ids']!, _relatedIdsMeta),
      );
    }
    if (data.containsKey('stage')) {
      context.handle(
        _stageMeta,
        stage.isAcceptableOrUnknown(data['stage']!, _stageMeta),
      );
    }
    if (data.containsKey('mastered')) {
      context.handle(
        _masteredMeta,
        mastered.isAcceptableOrUnknown(data['mastered']!, _masteredMeta),
      );
    }
    if (data.containsKey('total_reviews')) {
      context.handle(
        _totalReviewsMeta,
        totalReviews.isAcceptableOrUnknown(
          data['total_reviews']!,
          _totalReviewsMeta,
        ),
      );
    }
    if (data.containsKey('failed_count')) {
      context.handle(
        _failedCountMeta,
        failedCount.isAcceptableOrUnknown(
          data['failed_count']!,
          _failedCountMeta,
        ),
      );
    }
    if (data.containsKey('usage_count')) {
      context.handle(
        _usageCountMeta,
        usageCount.isAcceptableOrUnknown(data['usage_count']!, _usageCountMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CardsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CardsData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      cardType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_type'],
      )!,
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      sourceTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_title'],
      ),
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      importance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}importance'],
      )!,
      front: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}front'],
      ),
      back: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}back'],
      ),
      indexTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}index_title'],
      ),
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      ),
      highlight: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}highlight'],
      ),
      anchor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}anchor'],
      ),
      question: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question'],
      ),
      answer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer'],
      ),
      fillQuestion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fill_question'],
      ),
      fillAnswer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fill_answer'],
      ),
      choiceQuestion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}choice_question'],
      ),
      choiceOptions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}choice_options'],
      ),
      choiceCorrectIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}choice_correct_index'],
      ),
      tfStatement: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tf_statement'],
      ),
      tfIsTrue: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}tf_is_true'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      lastReviewDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_review_date'],
      ),
      nextReviewDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}next_review_date'],
      ),
      memoryLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}memory_level'],
      )!,
      relatedIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}related_ids'],
      )!,
      stage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage'],
      )!,
      mastered: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}mastered'],
      )!,
      totalReviews: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_reviews'],
      )!,
      failedCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}failed_count'],
      )!,
      usageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}usage_count'],
      )!,
    );
  }

  @override
  $CardsTable createAlias(String alias) {
    return $CardsTable(attachedDatabase, alias);
  }
}

class CardsData extends DataClass implements Insertable<CardsData> {
  final String id;
  final String cardType;
  final String sourceType;
  final String sourceId;
  final String? sourceTitle;
  final String tags;
  final String kind;
  final String importance;
  final String? front;
  final String? back;
  final String? indexTitle;
  final String? author;
  final String? highlight;
  final String? anchor;
  final String? question;
  final String? answer;
  final String? fillQuestion;
  final String? fillAnswer;
  final String? choiceQuestion;
  final String? choiceOptions;
  final int? choiceCorrectIndex;
  final String? tfStatement;
  final bool? tfIsTrue;
  final String createdAt;
  final String updatedAt;
  final String? lastReviewDate;
  final String? nextReviewDate;
  final double memoryLevel;
  final String relatedIds;
  final int stage;
  final bool mastered;
  final int totalReviews;
  final int failedCount;
  final int usageCount;
  const CardsData({
    required this.id,
    required this.cardType,
    required this.sourceType,
    required this.sourceId,
    this.sourceTitle,
    required this.tags,
    required this.kind,
    required this.importance,
    this.front,
    this.back,
    this.indexTitle,
    this.author,
    this.highlight,
    this.anchor,
    this.question,
    this.answer,
    this.fillQuestion,
    this.fillAnswer,
    this.choiceQuestion,
    this.choiceOptions,
    this.choiceCorrectIndex,
    this.tfStatement,
    this.tfIsTrue,
    required this.createdAt,
    required this.updatedAt,
    this.lastReviewDate,
    this.nextReviewDate,
    required this.memoryLevel,
    required this.relatedIds,
    required this.stage,
    required this.mastered,
    required this.totalReviews,
    required this.failedCount,
    required this.usageCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['card_type'] = Variable<String>(cardType);
    map['source_type'] = Variable<String>(sourceType);
    map['source_id'] = Variable<String>(sourceId);
    if (!nullToAbsent || sourceTitle != null) {
      map['source_title'] = Variable<String>(sourceTitle);
    }
    map['tags'] = Variable<String>(tags);
    map['kind'] = Variable<String>(kind);
    map['importance'] = Variable<String>(importance);
    if (!nullToAbsent || front != null) {
      map['front'] = Variable<String>(front);
    }
    if (!nullToAbsent || back != null) {
      map['back'] = Variable<String>(back);
    }
    if (!nullToAbsent || indexTitle != null) {
      map['index_title'] = Variable<String>(indexTitle);
    }
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    if (!nullToAbsent || highlight != null) {
      map['highlight'] = Variable<String>(highlight);
    }
    if (!nullToAbsent || anchor != null) {
      map['anchor'] = Variable<String>(anchor);
    }
    if (!nullToAbsent || question != null) {
      map['question'] = Variable<String>(question);
    }
    if (!nullToAbsent || answer != null) {
      map['answer'] = Variable<String>(answer);
    }
    if (!nullToAbsent || fillQuestion != null) {
      map['fill_question'] = Variable<String>(fillQuestion);
    }
    if (!nullToAbsent || fillAnswer != null) {
      map['fill_answer'] = Variable<String>(fillAnswer);
    }
    if (!nullToAbsent || choiceQuestion != null) {
      map['choice_question'] = Variable<String>(choiceQuestion);
    }
    if (!nullToAbsent || choiceOptions != null) {
      map['choice_options'] = Variable<String>(choiceOptions);
    }
    if (!nullToAbsent || choiceCorrectIndex != null) {
      map['choice_correct_index'] = Variable<int>(choiceCorrectIndex);
    }
    if (!nullToAbsent || tfStatement != null) {
      map['tf_statement'] = Variable<String>(tfStatement);
    }
    if (!nullToAbsent || tfIsTrue != null) {
      map['tf_is_true'] = Variable<bool>(tfIsTrue);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || lastReviewDate != null) {
      map['last_review_date'] = Variable<String>(lastReviewDate);
    }
    if (!nullToAbsent || nextReviewDate != null) {
      map['next_review_date'] = Variable<String>(nextReviewDate);
    }
    map['memory_level'] = Variable<double>(memoryLevel);
    map['related_ids'] = Variable<String>(relatedIds);
    map['stage'] = Variable<int>(stage);
    map['mastered'] = Variable<bool>(mastered);
    map['total_reviews'] = Variable<int>(totalReviews);
    map['failed_count'] = Variable<int>(failedCount);
    map['usage_count'] = Variable<int>(usageCount);
    return map;
  }

  CardsCompanion toCompanion(bool nullToAbsent) {
    return CardsCompanion(
      id: Value(id),
      cardType: Value(cardType),
      sourceType: Value(sourceType),
      sourceId: Value(sourceId),
      sourceTitle: sourceTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceTitle),
      tags: Value(tags),
      kind: Value(kind),
      importance: Value(importance),
      front: front == null && nullToAbsent
          ? const Value.absent()
          : Value(front),
      back: back == null && nullToAbsent ? const Value.absent() : Value(back),
      indexTitle: indexTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(indexTitle),
      author: author == null && nullToAbsent
          ? const Value.absent()
          : Value(author),
      highlight: highlight == null && nullToAbsent
          ? const Value.absent()
          : Value(highlight),
      anchor: anchor == null && nullToAbsent
          ? const Value.absent()
          : Value(anchor),
      question: question == null && nullToAbsent
          ? const Value.absent()
          : Value(question),
      answer: answer == null && nullToAbsent
          ? const Value.absent()
          : Value(answer),
      fillQuestion: fillQuestion == null && nullToAbsent
          ? const Value.absent()
          : Value(fillQuestion),
      fillAnswer: fillAnswer == null && nullToAbsent
          ? const Value.absent()
          : Value(fillAnswer),
      choiceQuestion: choiceQuestion == null && nullToAbsent
          ? const Value.absent()
          : Value(choiceQuestion),
      choiceOptions: choiceOptions == null && nullToAbsent
          ? const Value.absent()
          : Value(choiceOptions),
      choiceCorrectIndex: choiceCorrectIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(choiceCorrectIndex),
      tfStatement: tfStatement == null && nullToAbsent
          ? const Value.absent()
          : Value(tfStatement),
      tfIsTrue: tfIsTrue == null && nullToAbsent
          ? const Value.absent()
          : Value(tfIsTrue),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastReviewDate: lastReviewDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewDate),
      nextReviewDate: nextReviewDate == null && nullToAbsent
          ? const Value.absent()
          : Value(nextReviewDate),
      memoryLevel: Value(memoryLevel),
      relatedIds: Value(relatedIds),
      stage: Value(stage),
      mastered: Value(mastered),
      totalReviews: Value(totalReviews),
      failedCount: Value(failedCount),
      usageCount: Value(usageCount),
    );
  }

  factory CardsData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CardsData(
      id: serializer.fromJson<String>(json['id']),
      cardType: serializer.fromJson<String>(json['cardType']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      sourceTitle: serializer.fromJson<String?>(json['sourceTitle']),
      tags: serializer.fromJson<String>(json['tags']),
      kind: serializer.fromJson<String>(json['kind']),
      importance: serializer.fromJson<String>(json['importance']),
      front: serializer.fromJson<String?>(json['front']),
      back: serializer.fromJson<String?>(json['back']),
      indexTitle: serializer.fromJson<String?>(json['indexTitle']),
      author: serializer.fromJson<String?>(json['author']),
      highlight: serializer.fromJson<String?>(json['highlight']),
      anchor: serializer.fromJson<String?>(json['anchor']),
      question: serializer.fromJson<String?>(json['question']),
      answer: serializer.fromJson<String?>(json['answer']),
      fillQuestion: serializer.fromJson<String?>(json['fillQuestion']),
      fillAnswer: serializer.fromJson<String?>(json['fillAnswer']),
      choiceQuestion: serializer.fromJson<String?>(json['choiceQuestion']),
      choiceOptions: serializer.fromJson<String?>(json['choiceOptions']),
      choiceCorrectIndex: serializer.fromJson<int?>(json['choiceCorrectIndex']),
      tfStatement: serializer.fromJson<String?>(json['tfStatement']),
      tfIsTrue: serializer.fromJson<bool?>(json['tfIsTrue']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      lastReviewDate: serializer.fromJson<String?>(json['lastReviewDate']),
      nextReviewDate: serializer.fromJson<String?>(json['nextReviewDate']),
      memoryLevel: serializer.fromJson<double>(json['memoryLevel']),
      relatedIds: serializer.fromJson<String>(json['relatedIds']),
      stage: serializer.fromJson<int>(json['stage']),
      mastered: serializer.fromJson<bool>(json['mastered']),
      totalReviews: serializer.fromJson<int>(json['totalReviews']),
      failedCount: serializer.fromJson<int>(json['failedCount']),
      usageCount: serializer.fromJson<int>(json['usageCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'cardType': serializer.toJson<String>(cardType),
      'sourceType': serializer.toJson<String>(sourceType),
      'sourceId': serializer.toJson<String>(sourceId),
      'sourceTitle': serializer.toJson<String?>(sourceTitle),
      'tags': serializer.toJson<String>(tags),
      'kind': serializer.toJson<String>(kind),
      'importance': serializer.toJson<String>(importance),
      'front': serializer.toJson<String?>(front),
      'back': serializer.toJson<String?>(back),
      'indexTitle': serializer.toJson<String?>(indexTitle),
      'author': serializer.toJson<String?>(author),
      'highlight': serializer.toJson<String?>(highlight),
      'anchor': serializer.toJson<String?>(anchor),
      'question': serializer.toJson<String?>(question),
      'answer': serializer.toJson<String?>(answer),
      'fillQuestion': serializer.toJson<String?>(fillQuestion),
      'fillAnswer': serializer.toJson<String?>(fillAnswer),
      'choiceQuestion': serializer.toJson<String?>(choiceQuestion),
      'choiceOptions': serializer.toJson<String?>(choiceOptions),
      'choiceCorrectIndex': serializer.toJson<int?>(choiceCorrectIndex),
      'tfStatement': serializer.toJson<String?>(tfStatement),
      'tfIsTrue': serializer.toJson<bool?>(tfIsTrue),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'lastReviewDate': serializer.toJson<String?>(lastReviewDate),
      'nextReviewDate': serializer.toJson<String?>(nextReviewDate),
      'memoryLevel': serializer.toJson<double>(memoryLevel),
      'relatedIds': serializer.toJson<String>(relatedIds),
      'stage': serializer.toJson<int>(stage),
      'mastered': serializer.toJson<bool>(mastered),
      'totalReviews': serializer.toJson<int>(totalReviews),
      'failedCount': serializer.toJson<int>(failedCount),
      'usageCount': serializer.toJson<int>(usageCount),
    };
  }

  CardsData copyWith({
    String? id,
    String? cardType,
    String? sourceType,
    String? sourceId,
    Value<String?> sourceTitle = const Value.absent(),
    String? tags,
    String? kind,
    String? importance,
    Value<String?> front = const Value.absent(),
    Value<String?> back = const Value.absent(),
    Value<String?> indexTitle = const Value.absent(),
    Value<String?> author = const Value.absent(),
    Value<String?> highlight = const Value.absent(),
    Value<String?> anchor = const Value.absent(),
    Value<String?> question = const Value.absent(),
    Value<String?> answer = const Value.absent(),
    Value<String?> fillQuestion = const Value.absent(),
    Value<String?> fillAnswer = const Value.absent(),
    Value<String?> choiceQuestion = const Value.absent(),
    Value<String?> choiceOptions = const Value.absent(),
    Value<int?> choiceCorrectIndex = const Value.absent(),
    Value<String?> tfStatement = const Value.absent(),
    Value<bool?> tfIsTrue = const Value.absent(),
    String? createdAt,
    String? updatedAt,
    Value<String?> lastReviewDate = const Value.absent(),
    Value<String?> nextReviewDate = const Value.absent(),
    double? memoryLevel,
    String? relatedIds,
    int? stage,
    bool? mastered,
    int? totalReviews,
    int? failedCount,
    int? usageCount,
  }) => CardsData(
    id: id ?? this.id,
    cardType: cardType ?? this.cardType,
    sourceType: sourceType ?? this.sourceType,
    sourceId: sourceId ?? this.sourceId,
    sourceTitle: sourceTitle.present ? sourceTitle.value : this.sourceTitle,
    tags: tags ?? this.tags,
    kind: kind ?? this.kind,
    importance: importance ?? this.importance,
    front: front.present ? front.value : this.front,
    back: back.present ? back.value : this.back,
    indexTitle: indexTitle.present ? indexTitle.value : this.indexTitle,
    author: author.present ? author.value : this.author,
    highlight: highlight.present ? highlight.value : this.highlight,
    anchor: anchor.present ? anchor.value : this.anchor,
    question: question.present ? question.value : this.question,
    answer: answer.present ? answer.value : this.answer,
    fillQuestion: fillQuestion.present ? fillQuestion.value : this.fillQuestion,
    fillAnswer: fillAnswer.present ? fillAnswer.value : this.fillAnswer,
    choiceQuestion: choiceQuestion.present
        ? choiceQuestion.value
        : this.choiceQuestion,
    choiceOptions: choiceOptions.present
        ? choiceOptions.value
        : this.choiceOptions,
    choiceCorrectIndex: choiceCorrectIndex.present
        ? choiceCorrectIndex.value
        : this.choiceCorrectIndex,
    tfStatement: tfStatement.present ? tfStatement.value : this.tfStatement,
    tfIsTrue: tfIsTrue.present ? tfIsTrue.value : this.tfIsTrue,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastReviewDate: lastReviewDate.present
        ? lastReviewDate.value
        : this.lastReviewDate,
    nextReviewDate: nextReviewDate.present
        ? nextReviewDate.value
        : this.nextReviewDate,
    memoryLevel: memoryLevel ?? this.memoryLevel,
    relatedIds: relatedIds ?? this.relatedIds,
    stage: stage ?? this.stage,
    mastered: mastered ?? this.mastered,
    totalReviews: totalReviews ?? this.totalReviews,
    failedCount: failedCount ?? this.failedCount,
    usageCount: usageCount ?? this.usageCount,
  );
  CardsData copyWithCompanion(CardsCompanion data) {
    return CardsData(
      id: data.id.present ? data.id.value : this.id,
      cardType: data.cardType.present ? data.cardType.value : this.cardType,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      sourceTitle: data.sourceTitle.present
          ? data.sourceTitle.value
          : this.sourceTitle,
      tags: data.tags.present ? data.tags.value : this.tags,
      kind: data.kind.present ? data.kind.value : this.kind,
      importance: data.importance.present
          ? data.importance.value
          : this.importance,
      front: data.front.present ? data.front.value : this.front,
      back: data.back.present ? data.back.value : this.back,
      indexTitle: data.indexTitle.present
          ? data.indexTitle.value
          : this.indexTitle,
      author: data.author.present ? data.author.value : this.author,
      highlight: data.highlight.present ? data.highlight.value : this.highlight,
      anchor: data.anchor.present ? data.anchor.value : this.anchor,
      question: data.question.present ? data.question.value : this.question,
      answer: data.answer.present ? data.answer.value : this.answer,
      fillQuestion: data.fillQuestion.present
          ? data.fillQuestion.value
          : this.fillQuestion,
      fillAnswer: data.fillAnswer.present
          ? data.fillAnswer.value
          : this.fillAnswer,
      choiceQuestion: data.choiceQuestion.present
          ? data.choiceQuestion.value
          : this.choiceQuestion,
      choiceOptions: data.choiceOptions.present
          ? data.choiceOptions.value
          : this.choiceOptions,
      choiceCorrectIndex: data.choiceCorrectIndex.present
          ? data.choiceCorrectIndex.value
          : this.choiceCorrectIndex,
      tfStatement: data.tfStatement.present
          ? data.tfStatement.value
          : this.tfStatement,
      tfIsTrue: data.tfIsTrue.present ? data.tfIsTrue.value : this.tfIsTrue,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastReviewDate: data.lastReviewDate.present
          ? data.lastReviewDate.value
          : this.lastReviewDate,
      nextReviewDate: data.nextReviewDate.present
          ? data.nextReviewDate.value
          : this.nextReviewDate,
      memoryLevel: data.memoryLevel.present
          ? data.memoryLevel.value
          : this.memoryLevel,
      relatedIds: data.relatedIds.present
          ? data.relatedIds.value
          : this.relatedIds,
      stage: data.stage.present ? data.stage.value : this.stage,
      mastered: data.mastered.present ? data.mastered.value : this.mastered,
      totalReviews: data.totalReviews.present
          ? data.totalReviews.value
          : this.totalReviews,
      failedCount: data.failedCount.present
          ? data.failedCount.value
          : this.failedCount,
      usageCount: data.usageCount.present
          ? data.usageCount.value
          : this.usageCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CardsData(')
          ..write('id: $id, ')
          ..write('cardType: $cardType, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceId: $sourceId, ')
          ..write('sourceTitle: $sourceTitle, ')
          ..write('tags: $tags, ')
          ..write('kind: $kind, ')
          ..write('importance: $importance, ')
          ..write('front: $front, ')
          ..write('back: $back, ')
          ..write('indexTitle: $indexTitle, ')
          ..write('author: $author, ')
          ..write('highlight: $highlight, ')
          ..write('anchor: $anchor, ')
          ..write('question: $question, ')
          ..write('answer: $answer, ')
          ..write('fillQuestion: $fillQuestion, ')
          ..write('fillAnswer: $fillAnswer, ')
          ..write('choiceQuestion: $choiceQuestion, ')
          ..write('choiceOptions: $choiceOptions, ')
          ..write('choiceCorrectIndex: $choiceCorrectIndex, ')
          ..write('tfStatement: $tfStatement, ')
          ..write('tfIsTrue: $tfIsTrue, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastReviewDate: $lastReviewDate, ')
          ..write('nextReviewDate: $nextReviewDate, ')
          ..write('memoryLevel: $memoryLevel, ')
          ..write('relatedIds: $relatedIds, ')
          ..write('stage: $stage, ')
          ..write('mastered: $mastered, ')
          ..write('totalReviews: $totalReviews, ')
          ..write('failedCount: $failedCount, ')
          ..write('usageCount: $usageCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    cardType,
    sourceType,
    sourceId,
    sourceTitle,
    tags,
    kind,
    importance,
    front,
    back,
    indexTitle,
    author,
    highlight,
    anchor,
    question,
    answer,
    fillQuestion,
    fillAnswer,
    choiceQuestion,
    choiceOptions,
    choiceCorrectIndex,
    tfStatement,
    tfIsTrue,
    createdAt,
    updatedAt,
    lastReviewDate,
    nextReviewDate,
    memoryLevel,
    relatedIds,
    stage,
    mastered,
    totalReviews,
    failedCount,
    usageCount,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardsData &&
          other.id == this.id &&
          other.cardType == this.cardType &&
          other.sourceType == this.sourceType &&
          other.sourceId == this.sourceId &&
          other.sourceTitle == this.sourceTitle &&
          other.tags == this.tags &&
          other.kind == this.kind &&
          other.importance == this.importance &&
          other.front == this.front &&
          other.back == this.back &&
          other.indexTitle == this.indexTitle &&
          other.author == this.author &&
          other.highlight == this.highlight &&
          other.anchor == this.anchor &&
          other.question == this.question &&
          other.answer == this.answer &&
          other.fillQuestion == this.fillQuestion &&
          other.fillAnswer == this.fillAnswer &&
          other.choiceQuestion == this.choiceQuestion &&
          other.choiceOptions == this.choiceOptions &&
          other.choiceCorrectIndex == this.choiceCorrectIndex &&
          other.tfStatement == this.tfStatement &&
          other.tfIsTrue == this.tfIsTrue &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastReviewDate == this.lastReviewDate &&
          other.nextReviewDate == this.nextReviewDate &&
          other.memoryLevel == this.memoryLevel &&
          other.relatedIds == this.relatedIds &&
          other.stage == this.stage &&
          other.mastered == this.mastered &&
          other.totalReviews == this.totalReviews &&
          other.failedCount == this.failedCount &&
          other.usageCount == this.usageCount);
}

class CardsCompanion extends UpdateCompanion<CardsData> {
  final Value<String> id;
  final Value<String> cardType;
  final Value<String> sourceType;
  final Value<String> sourceId;
  final Value<String?> sourceTitle;
  final Value<String> tags;
  final Value<String> kind;
  final Value<String> importance;
  final Value<String?> front;
  final Value<String?> back;
  final Value<String?> indexTitle;
  final Value<String?> author;
  final Value<String?> highlight;
  final Value<String?> anchor;
  final Value<String?> question;
  final Value<String?> answer;
  final Value<String?> fillQuestion;
  final Value<String?> fillAnswer;
  final Value<String?> choiceQuestion;
  final Value<String?> choiceOptions;
  final Value<int?> choiceCorrectIndex;
  final Value<String?> tfStatement;
  final Value<bool?> tfIsTrue;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String?> lastReviewDate;
  final Value<String?> nextReviewDate;
  final Value<double> memoryLevel;
  final Value<String> relatedIds;
  final Value<int> stage;
  final Value<bool> mastered;
  final Value<int> totalReviews;
  final Value<int> failedCount;
  final Value<int> usageCount;
  final Value<int> rowid;
  const CardsCompanion({
    this.id = const Value.absent(),
    this.cardType = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.sourceTitle = const Value.absent(),
    this.tags = const Value.absent(),
    this.kind = const Value.absent(),
    this.importance = const Value.absent(),
    this.front = const Value.absent(),
    this.back = const Value.absent(),
    this.indexTitle = const Value.absent(),
    this.author = const Value.absent(),
    this.highlight = const Value.absent(),
    this.anchor = const Value.absent(),
    this.question = const Value.absent(),
    this.answer = const Value.absent(),
    this.fillQuestion = const Value.absent(),
    this.fillAnswer = const Value.absent(),
    this.choiceQuestion = const Value.absent(),
    this.choiceOptions = const Value.absent(),
    this.choiceCorrectIndex = const Value.absent(),
    this.tfStatement = const Value.absent(),
    this.tfIsTrue = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastReviewDate = const Value.absent(),
    this.nextReviewDate = const Value.absent(),
    this.memoryLevel = const Value.absent(),
    this.relatedIds = const Value.absent(),
    this.stage = const Value.absent(),
    this.mastered = const Value.absent(),
    this.totalReviews = const Value.absent(),
    this.failedCount = const Value.absent(),
    this.usageCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CardsCompanion.insert({
    required String id,
    required String cardType,
    this.sourceType = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.sourceTitle = const Value.absent(),
    this.tags = const Value.absent(),
    this.kind = const Value.absent(),
    this.importance = const Value.absent(),
    this.front = const Value.absent(),
    this.back = const Value.absent(),
    this.indexTitle = const Value.absent(),
    this.author = const Value.absent(),
    this.highlight = const Value.absent(),
    this.anchor = const Value.absent(),
    this.question = const Value.absent(),
    this.answer = const Value.absent(),
    this.fillQuestion = const Value.absent(),
    this.fillAnswer = const Value.absent(),
    this.choiceQuestion = const Value.absent(),
    this.choiceOptions = const Value.absent(),
    this.choiceCorrectIndex = const Value.absent(),
    this.tfStatement = const Value.absent(),
    this.tfIsTrue = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastReviewDate = const Value.absent(),
    this.nextReviewDate = const Value.absent(),
    this.memoryLevel = const Value.absent(),
    this.relatedIds = const Value.absent(),
    this.stage = const Value.absent(),
    this.mastered = const Value.absent(),
    this.totalReviews = const Value.absent(),
    this.failedCount = const Value.absent(),
    this.usageCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       cardType = Value(cardType);
  static Insertable<CardsData> custom({
    Expression<String>? id,
    Expression<String>? cardType,
    Expression<String>? sourceType,
    Expression<String>? sourceId,
    Expression<String>? sourceTitle,
    Expression<String>? tags,
    Expression<String>? kind,
    Expression<String>? importance,
    Expression<String>? front,
    Expression<String>? back,
    Expression<String>? indexTitle,
    Expression<String>? author,
    Expression<String>? highlight,
    Expression<String>? anchor,
    Expression<String>? question,
    Expression<String>? answer,
    Expression<String>? fillQuestion,
    Expression<String>? fillAnswer,
    Expression<String>? choiceQuestion,
    Expression<String>? choiceOptions,
    Expression<int>? choiceCorrectIndex,
    Expression<String>? tfStatement,
    Expression<bool>? tfIsTrue,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? lastReviewDate,
    Expression<String>? nextReviewDate,
    Expression<double>? memoryLevel,
    Expression<String>? relatedIds,
    Expression<int>? stage,
    Expression<bool>? mastered,
    Expression<int>? totalReviews,
    Expression<int>? failedCount,
    Expression<int>? usageCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cardType != null) 'card_type': cardType,
      if (sourceType != null) 'source_type': sourceType,
      if (sourceId != null) 'source_id': sourceId,
      if (sourceTitle != null) 'source_title': sourceTitle,
      if (tags != null) 'tags': tags,
      if (kind != null) 'kind': kind,
      if (importance != null) 'importance': importance,
      if (front != null) 'front': front,
      if (back != null) 'back': back,
      if (indexTitle != null) 'index_title': indexTitle,
      if (author != null) 'author': author,
      if (highlight != null) 'highlight': highlight,
      if (anchor != null) 'anchor': anchor,
      if (question != null) 'question': question,
      if (answer != null) 'answer': answer,
      if (fillQuestion != null) 'fill_question': fillQuestion,
      if (fillAnswer != null) 'fill_answer': fillAnswer,
      if (choiceQuestion != null) 'choice_question': choiceQuestion,
      if (choiceOptions != null) 'choice_options': choiceOptions,
      if (choiceCorrectIndex != null)
        'choice_correct_index': choiceCorrectIndex,
      if (tfStatement != null) 'tf_statement': tfStatement,
      if (tfIsTrue != null) 'tf_is_true': tfIsTrue,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastReviewDate != null) 'last_review_date': lastReviewDate,
      if (nextReviewDate != null) 'next_review_date': nextReviewDate,
      if (memoryLevel != null) 'memory_level': memoryLevel,
      if (relatedIds != null) 'related_ids': relatedIds,
      if (stage != null) 'stage': stage,
      if (mastered != null) 'mastered': mastered,
      if (totalReviews != null) 'total_reviews': totalReviews,
      if (failedCount != null) 'failed_count': failedCount,
      if (usageCount != null) 'usage_count': usageCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CardsCompanion copyWith({
    Value<String>? id,
    Value<String>? cardType,
    Value<String>? sourceType,
    Value<String>? sourceId,
    Value<String?>? sourceTitle,
    Value<String>? tags,
    Value<String>? kind,
    Value<String>? importance,
    Value<String?>? front,
    Value<String?>? back,
    Value<String?>? indexTitle,
    Value<String?>? author,
    Value<String?>? highlight,
    Value<String?>? anchor,
    Value<String?>? question,
    Value<String?>? answer,
    Value<String?>? fillQuestion,
    Value<String?>? fillAnswer,
    Value<String?>? choiceQuestion,
    Value<String?>? choiceOptions,
    Value<int?>? choiceCorrectIndex,
    Value<String?>? tfStatement,
    Value<bool?>? tfIsTrue,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String?>? lastReviewDate,
    Value<String?>? nextReviewDate,
    Value<double>? memoryLevel,
    Value<String>? relatedIds,
    Value<int>? stage,
    Value<bool>? mastered,
    Value<int>? totalReviews,
    Value<int>? failedCount,
    Value<int>? usageCount,
    Value<int>? rowid,
  }) {
    return CardsCompanion(
      id: id ?? this.id,
      cardType: cardType ?? this.cardType,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      sourceTitle: sourceTitle ?? this.sourceTitle,
      tags: tags ?? this.tags,
      kind: kind ?? this.kind,
      importance: importance ?? this.importance,
      front: front ?? this.front,
      back: back ?? this.back,
      indexTitle: indexTitle ?? this.indexTitle,
      author: author ?? this.author,
      highlight: highlight ?? this.highlight,
      anchor: anchor ?? this.anchor,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      fillQuestion: fillQuestion ?? this.fillQuestion,
      fillAnswer: fillAnswer ?? this.fillAnswer,
      choiceQuestion: choiceQuestion ?? this.choiceQuestion,
      choiceOptions: choiceOptions ?? this.choiceOptions,
      choiceCorrectIndex: choiceCorrectIndex ?? this.choiceCorrectIndex,
      tfStatement: tfStatement ?? this.tfStatement,
      tfIsTrue: tfIsTrue ?? this.tfIsTrue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastReviewDate: lastReviewDate ?? this.lastReviewDate,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      memoryLevel: memoryLevel ?? this.memoryLevel,
      relatedIds: relatedIds ?? this.relatedIds,
      stage: stage ?? this.stage,
      mastered: mastered ?? this.mastered,
      totalReviews: totalReviews ?? this.totalReviews,
      failedCount: failedCount ?? this.failedCount,
      usageCount: usageCount ?? this.usageCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (cardType.present) {
      map['card_type'] = Variable<String>(cardType.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (sourceTitle.present) {
      map['source_title'] = Variable<String>(sourceTitle.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (importance.present) {
      map['importance'] = Variable<String>(importance.value);
    }
    if (front.present) {
      map['front'] = Variable<String>(front.value);
    }
    if (back.present) {
      map['back'] = Variable<String>(back.value);
    }
    if (indexTitle.present) {
      map['index_title'] = Variable<String>(indexTitle.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (highlight.present) {
      map['highlight'] = Variable<String>(highlight.value);
    }
    if (anchor.present) {
      map['anchor'] = Variable<String>(anchor.value);
    }
    if (question.present) {
      map['question'] = Variable<String>(question.value);
    }
    if (answer.present) {
      map['answer'] = Variable<String>(answer.value);
    }
    if (fillQuestion.present) {
      map['fill_question'] = Variable<String>(fillQuestion.value);
    }
    if (fillAnswer.present) {
      map['fill_answer'] = Variable<String>(fillAnswer.value);
    }
    if (choiceQuestion.present) {
      map['choice_question'] = Variable<String>(choiceQuestion.value);
    }
    if (choiceOptions.present) {
      map['choice_options'] = Variable<String>(choiceOptions.value);
    }
    if (choiceCorrectIndex.present) {
      map['choice_correct_index'] = Variable<int>(choiceCorrectIndex.value);
    }
    if (tfStatement.present) {
      map['tf_statement'] = Variable<String>(tfStatement.value);
    }
    if (tfIsTrue.present) {
      map['tf_is_true'] = Variable<bool>(tfIsTrue.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (lastReviewDate.present) {
      map['last_review_date'] = Variable<String>(lastReviewDate.value);
    }
    if (nextReviewDate.present) {
      map['next_review_date'] = Variable<String>(nextReviewDate.value);
    }
    if (memoryLevel.present) {
      map['memory_level'] = Variable<double>(memoryLevel.value);
    }
    if (relatedIds.present) {
      map['related_ids'] = Variable<String>(relatedIds.value);
    }
    if (stage.present) {
      map['stage'] = Variable<int>(stage.value);
    }
    if (mastered.present) {
      map['mastered'] = Variable<bool>(mastered.value);
    }
    if (totalReviews.present) {
      map['total_reviews'] = Variable<int>(totalReviews.value);
    }
    if (failedCount.present) {
      map['failed_count'] = Variable<int>(failedCount.value);
    }
    if (usageCount.present) {
      map['usage_count'] = Variable<int>(usageCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardsCompanion(')
          ..write('id: $id, ')
          ..write('cardType: $cardType, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceId: $sourceId, ')
          ..write('sourceTitle: $sourceTitle, ')
          ..write('tags: $tags, ')
          ..write('kind: $kind, ')
          ..write('importance: $importance, ')
          ..write('front: $front, ')
          ..write('back: $back, ')
          ..write('indexTitle: $indexTitle, ')
          ..write('author: $author, ')
          ..write('highlight: $highlight, ')
          ..write('anchor: $anchor, ')
          ..write('question: $question, ')
          ..write('answer: $answer, ')
          ..write('fillQuestion: $fillQuestion, ')
          ..write('fillAnswer: $fillAnswer, ')
          ..write('choiceQuestion: $choiceQuestion, ')
          ..write('choiceOptions: $choiceOptions, ')
          ..write('choiceCorrectIndex: $choiceCorrectIndex, ')
          ..write('tfStatement: $tfStatement, ')
          ..write('tfIsTrue: $tfIsTrue, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastReviewDate: $lastReviewDate, ')
          ..write('nextReviewDate: $nextReviewDate, ')
          ..write('memoryLevel: $memoryLevel, ')
          ..write('relatedIds: $relatedIds, ')
          ..write('stage: $stage, ')
          ..write('mastered: $mastered, ')
          ..write('totalReviews: $totalReviews, ')
          ..write('failedCount: $failedCount, ')
          ..write('usageCount: $usageCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $NotesTable notes = $NotesTable(this);
  late final $NodesTable nodes = $NodesTable(this);
  late final $BooksTable books = $BooksTable(this);
  late final $BookAnnotationsTable bookAnnotations = $BookAnnotationsTable(
    this,
  );
  late final $BookHighlightsTable bookHighlights = $BookHighlightsTable(this);
  late final $BookBookmarksTable bookBookmarks = $BookBookmarksTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $PetsTable pets = $PetsTable(this);
  late final $UserSettingsTableTable userSettingsTable =
      $UserSettingsTableTable(this);
  late final $IsbnCacheTable isbnCache = $IsbnCacheTable(this);
  late final $PdfDrawingsTable pdfDrawings = $PdfDrawingsTable(this);
  late final $BoardViewsTable boardViews = $BoardViewsTable(this);
  late final $BoardNodesTable boardNodes = $BoardNodesTable(this);
  late final $BoardEdgesTable boardEdges = $BoardEdgesTable(this);
  late final $BoardGroupsTable boardGroups = $BoardGroupsTable(this);
  late final $BoardTextsTable boardTexts = $BoardTextsTable(this);
  late final $BoardStrokesTable boardStrokes = $BoardStrokesTable(this);
  late final $BoardAlbumsTable boardAlbums = $BoardAlbumsTable(this);
  late final $NoteBookLinksTable noteBookLinks = $NoteBookLinksTable(this);
  late final $NoteNoteLinksTable noteNoteLinks = $NoteNoteLinksTable(this);
  late final $SparksTable sparks = $SparksTable(this);
  late final $NodeAnnotationsTable nodeAnnotations = $NodeAnnotationsTable(
    this,
  );
  late final $TagIndexTable tagIndex = $TagIndexTable(this);
  late final $SearchIndexTable searchIndex = $SearchIndexTable(this);
  late final $WritingSessionsTable writingSessions = $WritingSessionsTable(
    this,
  );
  late final $FocusSessionsTable focusSessions = $FocusSessionsTable(this);
  late final $ReadingStatsTable readingStats = $ReadingStatsTable(this);
  late final $CardsTable cards = $CardsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    notes,
    nodes,
    books,
    bookAnnotations,
    bookHighlights,
    bookBookmarks,
    tasks,
    pets,
    userSettingsTable,
    isbnCache,
    pdfDrawings,
    boardViews,
    boardNodes,
    boardEdges,
    boardGroups,
    boardTexts,
    boardStrokes,
    boardAlbums,
    noteBookLinks,
    noteNoteLinks,
    sparks,
    nodeAnnotations,
    tagIndex,
    searchIndex,
    writingSessions,
    focusSessions,
    readingStats,
    cards,
  ];
}

typedef $$NotesTableCreateCompanionBuilder =
    NotesCompanion Function({
      required String id,
      Value<String> title,
      Value<String> content,
      Value<String?> updatedAt,
      Value<String> status,
      Value<String> editorMode,
      Value<int> isLocked,
      Value<String> tags,
      Value<String?> inquiryQuestion,
      Value<String?> inquiryConclusion,
      Value<String> exploreTasks,
      Value<String> contentFormat,
      Value<String?> createdAt,
      Value<int> rowid,
    });
typedef $$NotesTableUpdateCompanionBuilder =
    NotesCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> content,
      Value<String?> updatedAt,
      Value<String> status,
      Value<String> editorMode,
      Value<int> isLocked,
      Value<String> tags,
      Value<String?> inquiryQuestion,
      Value<String?> inquiryConclusion,
      Value<String> exploreTasks,
      Value<String> contentFormat,
      Value<String?> createdAt,
      Value<int> rowid,
    });

class $$NotesTableFilterComposer extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get editorMode => $composableBuilder(
    column: $table.editorMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isLocked => $composableBuilder(
    column: $table.isLocked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inquiryQuestion => $composableBuilder(
    column: $table.inquiryQuestion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inquiryConclusion => $composableBuilder(
    column: $table.inquiryConclusion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exploreTasks => $composableBuilder(
    column: $table.exploreTasks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentFormat => $composableBuilder(
    column: $table.contentFormat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get editorMode => $composableBuilder(
    column: $table.editorMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isLocked => $composableBuilder(
    column: $table.isLocked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inquiryQuestion => $composableBuilder(
    column: $table.inquiryQuestion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inquiryConclusion => $composableBuilder(
    column: $table.inquiryConclusion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exploreTasks => $composableBuilder(
    column: $table.exploreTasks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentFormat => $composableBuilder(
    column: $table.contentFormat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get editorMode => $composableBuilder(
    column: $table.editorMode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isLocked =>
      $composableBuilder(column: $table.isLocked, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get inquiryQuestion => $composableBuilder(
    column: $table.inquiryQuestion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get inquiryConclusion => $composableBuilder(
    column: $table.inquiryConclusion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exploreTasks => $composableBuilder(
    column: $table.exploreTasks,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentFormat => $composableBuilder(
    column: $table.contentFormat,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$NotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotesTable,
          Note,
          $$NotesTableFilterComposer,
          $$NotesTableOrderingComposer,
          $$NotesTableAnnotationComposer,
          $$NotesTableCreateCompanionBuilder,
          $$NotesTableUpdateCompanionBuilder,
          (Note, BaseReferences<_$AppDatabase, $NotesTable, Note>),
          Note,
          PrefetchHooks Function()
        > {
  $$NotesTableTableManager(_$AppDatabase db, $NotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> editorMode = const Value.absent(),
                Value<int> isLocked = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<String?> inquiryQuestion = const Value.absent(),
                Value<String?> inquiryConclusion = const Value.absent(),
                Value<String> exploreTasks = const Value.absent(),
                Value<String> contentFormat = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion(
                id: id,
                title: title,
                content: content,
                updatedAt: updatedAt,
                status: status,
                editorMode: editorMode,
                isLocked: isLocked,
                tags: tags,
                inquiryQuestion: inquiryQuestion,
                inquiryConclusion: inquiryConclusion,
                exploreTasks: exploreTasks,
                contentFormat: contentFormat,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> editorMode = const Value.absent(),
                Value<int> isLocked = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<String?> inquiryQuestion = const Value.absent(),
                Value<String?> inquiryConclusion = const Value.absent(),
                Value<String> exploreTasks = const Value.absent(),
                Value<String> contentFormat = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion.insert(
                id: id,
                title: title,
                content: content,
                updatedAt: updatedAt,
                status: status,
                editorMode: editorMode,
                isLocked: isLocked,
                tags: tags,
                inquiryQuestion: inquiryQuestion,
                inquiryConclusion: inquiryConclusion,
                exploreTasks: exploreTasks,
                contentFormat: contentFormat,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NotesTable, Note>(table),
                  BaseReferences<_$AppDatabase, $NotesTable, Note>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotesTable,
      Note,
      $$NotesTableFilterComposer,
      $$NotesTableOrderingComposer,
      $$NotesTableAnnotationComposer,
      $$NotesTableCreateCompanionBuilder,
      $$NotesTableUpdateCompanionBuilder,
      (Note, BaseReferences<_$AppDatabase, $NotesTable, Note>),
      Note,
      PrefetchHooks Function()
    >;
typedef $$NodesTableCreateCompanionBuilder =
    NodesCompanion Function({
      required String id,
      Value<String> title,
      Value<String?> parentId,
      Value<bool> isFolder,
      Value<String> nodeType,
      Value<String?> targetId,
      Value<int> sortOrder,
      Value<String> tags,
      Value<String?> systemTag,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<int> rowid,
    });
typedef $$NodesTableUpdateCompanionBuilder =
    NodesCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String?> parentId,
      Value<bool> isFolder,
      Value<String> nodeType,
      Value<String?> targetId,
      Value<int> sortOrder,
      Value<String> tags,
      Value<String?> systemTag,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<int> rowid,
    });

class $$NodesTableFilterComposer extends Composer<_$AppDatabase, $NodesTable> {
  $$NodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFolder => $composableBuilder(
    column: $table.isFolder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nodeType => $composableBuilder(
    column: $table.nodeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get systemTag => $composableBuilder(
    column: $table.systemTag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NodesTableOrderingComposer
    extends Composer<_$AppDatabase, $NodesTable> {
  $$NodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFolder => $composableBuilder(
    column: $table.isFolder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nodeType => $composableBuilder(
    column: $table.nodeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get systemTag => $composableBuilder(
    column: $table.systemTag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NodesTable> {
  $$NodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<bool> get isFolder =>
      $composableBuilder(column: $table.isFolder, builder: (column) => column);

  GeneratedColumn<String> get nodeType =>
      $composableBuilder(column: $table.nodeType, builder: (column) => column);

  GeneratedColumn<String> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get systemTag =>
      $composableBuilder(column: $table.systemTag, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$NodesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NodesTable,
          NodeRow,
          $$NodesTableFilterComposer,
          $$NodesTableOrderingComposer,
          $$NodesTableAnnotationComposer,
          $$NodesTableCreateCompanionBuilder,
          $$NodesTableUpdateCompanionBuilder,
          (NodeRow, BaseReferences<_$AppDatabase, $NodesTable, NodeRow>),
          NodeRow,
          PrefetchHooks Function()
        > {
  $$NodesTableTableManager(_$AppDatabase db, $NodesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<bool> isFolder = const Value.absent(),
                Value<String> nodeType = const Value.absent(),
                Value<String?> targetId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<String?> systemTag = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NodesCompanion(
                id: id,
                title: title,
                parentId: parentId,
                isFolder: isFolder,
                nodeType: nodeType,
                targetId: targetId,
                sortOrder: sortOrder,
                tags: tags,
                systemTag: systemTag,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> title = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<bool> isFolder = const Value.absent(),
                Value<String> nodeType = const Value.absent(),
                Value<String?> targetId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<String?> systemTag = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NodesCompanion.insert(
                id: id,
                title: title,
                parentId: parentId,
                isFolder: isFolder,
                nodeType: nodeType,
                targetId: targetId,
                sortOrder: sortOrder,
                tags: tags,
                systemTag: systemTag,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NodesTable, NodeRow>(table),
                  BaseReferences<_$AppDatabase, $NodesTable, NodeRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NodesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NodesTable,
      NodeRow,
      $$NodesTableFilterComposer,
      $$NodesTableOrderingComposer,
      $$NodesTableAnnotationComposer,
      $$NodesTableCreateCompanionBuilder,
      $$NodesTableUpdateCompanionBuilder,
      (NodeRow, BaseReferences<_$AppDatabase, $NodesTable, NodeRow>),
      NodeRow,
      PrefetchHooks Function()
    >;
typedef $$BooksTableCreateCompanionBuilder =
    BooksCompanion Function({
      required String id,
      Value<String> title,
      Value<String> author,
      Value<String> isbn,
      Value<String?> coverUrl,
      Value<String?> filePath,
      Value<String> fileType,
      Value<String?> fileName,
      Value<int> fileSize,
      Value<String> status,
      Value<int> readingProgress,
      Value<int> totalPages,
      Value<String?> createdAt,
      Value<String?> lastReadAt,
      Value<String> source,
      Value<String?> summary,
      Value<double?> rating,
      Value<String?> review,
      Value<int> rowid,
    });
typedef $$BooksTableUpdateCompanionBuilder =
    BooksCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> author,
      Value<String> isbn,
      Value<String?> coverUrl,
      Value<String?> filePath,
      Value<String> fileType,
      Value<String?> fileName,
      Value<int> fileSize,
      Value<String> status,
      Value<int> readingProgress,
      Value<int> totalPages,
      Value<String?> createdAt,
      Value<String?> lastReadAt,
      Value<String> source,
      Value<String?> summary,
      Value<double?> rating,
      Value<String?> review,
      Value<int> rowid,
    });

class $$BooksTableFilterComposer extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get isbn => $composableBuilder(
    column: $table.isbn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileType => $composableBuilder(
    column: $table.fileType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get readingProgress => $composableBuilder(
    column: $table.readingProgress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalPages => $composableBuilder(
    column: $table.totalPages,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get review => $composableBuilder(
    column: $table.review,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BooksTableOrderingComposer
    extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get isbn => $composableBuilder(
    column: $table.isbn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileType => $composableBuilder(
    column: $table.fileType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get readingProgress => $composableBuilder(
    column: $table.readingProgress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalPages => $composableBuilder(
    column: $table.totalPages,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get review => $composableBuilder(
    column: $table.review,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BooksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get isbn =>
      $composableBuilder(column: $table.isbn, builder: (column) => column);

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get fileType =>
      $composableBuilder(column: $table.fileType, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get readingProgress => $composableBuilder(
    column: $table.readingProgress,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalPages => $composableBuilder(
    column: $table.totalPages,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<String> get review =>
      $composableBuilder(column: $table.review, builder: (column) => column);
}

class $$BooksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BooksTable,
          BookRow,
          $$BooksTableFilterComposer,
          $$BooksTableOrderingComposer,
          $$BooksTableAnnotationComposer,
          $$BooksTableCreateCompanionBuilder,
          $$BooksTableUpdateCompanionBuilder,
          (BookRow, BaseReferences<_$AppDatabase, $BooksTable, BookRow>),
          BookRow,
          PrefetchHooks Function()
        > {
  $$BooksTableTableManager(_$AppDatabase db, $BooksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> author = const Value.absent(),
                Value<String> isbn = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<String?> filePath = const Value.absent(),
                Value<String> fileType = const Value.absent(),
                Value<String?> fileName = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> readingProgress = const Value.absent(),
                Value<int> totalPages = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> lastReadAt = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> summary = const Value.absent(),
                Value<double?> rating = const Value.absent(),
                Value<String?> review = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BooksCompanion(
                id: id,
                title: title,
                author: author,
                isbn: isbn,
                coverUrl: coverUrl,
                filePath: filePath,
                fileType: fileType,
                fileName: fileName,
                fileSize: fileSize,
                status: status,
                readingProgress: readingProgress,
                totalPages: totalPages,
                createdAt: createdAt,
                lastReadAt: lastReadAt,
                source: source,
                summary: summary,
                rating: rating,
                review: review,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> title = const Value.absent(),
                Value<String> author = const Value.absent(),
                Value<String> isbn = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<String?> filePath = const Value.absent(),
                Value<String> fileType = const Value.absent(),
                Value<String?> fileName = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> readingProgress = const Value.absent(),
                Value<int> totalPages = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> lastReadAt = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> summary = const Value.absent(),
                Value<double?> rating = const Value.absent(),
                Value<String?> review = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BooksCompanion.insert(
                id: id,
                title: title,
                author: author,
                isbn: isbn,
                coverUrl: coverUrl,
                filePath: filePath,
                fileType: fileType,
                fileName: fileName,
                fileSize: fileSize,
                status: status,
                readingProgress: readingProgress,
                totalPages: totalPages,
                createdAt: createdAt,
                lastReadAt: lastReadAt,
                source: source,
                summary: summary,
                rating: rating,
                review: review,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BooksTable, BookRow>(table),
                  BaseReferences<_$AppDatabase, $BooksTable, BookRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BooksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BooksTable,
      BookRow,
      $$BooksTableFilterComposer,
      $$BooksTableOrderingComposer,
      $$BooksTableAnnotationComposer,
      $$BooksTableCreateCompanionBuilder,
      $$BooksTableUpdateCompanionBuilder,
      (BookRow, BaseReferences<_$AppDatabase, $BooksTable, BookRow>),
      BookRow,
      PrefetchHooks Function()
    >;
typedef $$BookAnnotationsTableCreateCompanionBuilder =
    BookAnnotationsCompanion Function({
      required String id,
      Value<String?> bookId,
      Value<int?> pageNumber,
      Value<String?> quote,
      Value<String?> note,
      Value<String?> color,
      Value<String?> createdAt,
      Value<int> rowid,
    });
typedef $$BookAnnotationsTableUpdateCompanionBuilder =
    BookAnnotationsCompanion Function({
      Value<String> id,
      Value<String?> bookId,
      Value<int?> pageNumber,
      Value<String?> quote,
      Value<String?> note,
      Value<String?> color,
      Value<String?> createdAt,
      Value<int> rowid,
    });

class $$BookAnnotationsTableFilterComposer
    extends Composer<_$AppDatabase, $BookAnnotationsTable> {
  $$BookAnnotationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quote => $composableBuilder(
    column: $table.quote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BookAnnotationsTableOrderingComposer
    extends Composer<_$AppDatabase, $BookAnnotationsTable> {
  $$BookAnnotationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quote => $composableBuilder(
    column: $table.quote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BookAnnotationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookAnnotationsTable> {
  $$BookAnnotationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bookId =>
      $composableBuilder(column: $table.bookId, builder: (column) => column);

  GeneratedColumn<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get quote =>
      $composableBuilder(column: $table.quote, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$BookAnnotationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BookAnnotationsTable,
          BookAnnotation,
          $$BookAnnotationsTableFilterComposer,
          $$BookAnnotationsTableOrderingComposer,
          $$BookAnnotationsTableAnnotationComposer,
          $$BookAnnotationsTableCreateCompanionBuilder,
          $$BookAnnotationsTableUpdateCompanionBuilder,
          (
            BookAnnotation,
            BaseReferences<
              _$AppDatabase,
              $BookAnnotationsTable,
              BookAnnotation
            >,
          ),
          BookAnnotation,
          PrefetchHooks Function()
        > {
  $$BookAnnotationsTableTableManager(
    _$AppDatabase db,
    $BookAnnotationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookAnnotationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookAnnotationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookAnnotationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> bookId = const Value.absent(),
                Value<int?> pageNumber = const Value.absent(),
                Value<String?> quote = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookAnnotationsCompanion(
                id: id,
                bookId: bookId,
                pageNumber: pageNumber,
                quote: quote,
                note: note,
                color: color,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> bookId = const Value.absent(),
                Value<int?> pageNumber = const Value.absent(),
                Value<String?> quote = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookAnnotationsCompanion.insert(
                id: id,
                bookId: bookId,
                pageNumber: pageNumber,
                quote: quote,
                note: note,
                color: color,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BookAnnotationsTable, BookAnnotation>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $BookAnnotationsTable,
                    BookAnnotation
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BookAnnotationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BookAnnotationsTable,
      BookAnnotation,
      $$BookAnnotationsTableFilterComposer,
      $$BookAnnotationsTableOrderingComposer,
      $$BookAnnotationsTableAnnotationComposer,
      $$BookAnnotationsTableCreateCompanionBuilder,
      $$BookAnnotationsTableUpdateCompanionBuilder,
      (
        BookAnnotation,
        BaseReferences<_$AppDatabase, $BookAnnotationsTable, BookAnnotation>,
      ),
      BookAnnotation,
      PrefetchHooks Function()
    >;
typedef $$BookHighlightsTableCreateCompanionBuilder =
    BookHighlightsCompanion Function({
      required String id,
      Value<String?> bookId,
      Value<String?> chapter,
      Value<String?> location,
      Value<String?> textContent,
      Value<String?> color,
      Value<String?> note,
      Value<String?> createdAt,
      Value<String?> source,
      Value<int> rowid,
    });
typedef $$BookHighlightsTableUpdateCompanionBuilder =
    BookHighlightsCompanion Function({
      Value<String> id,
      Value<String?> bookId,
      Value<String?> chapter,
      Value<String?> location,
      Value<String?> textContent,
      Value<String?> color,
      Value<String?> note,
      Value<String?> createdAt,
      Value<String?> source,
      Value<int> rowid,
    });

class $$BookHighlightsTableFilterComposer
    extends Composer<_$AppDatabase, $BookHighlightsTable> {
  $$BookHighlightsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textContent => $composableBuilder(
    column: $table.textContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BookHighlightsTableOrderingComposer
    extends Composer<_$AppDatabase, $BookHighlightsTable> {
  $$BookHighlightsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textContent => $composableBuilder(
    column: $table.textContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BookHighlightsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookHighlightsTable> {
  $$BookHighlightsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bookId =>
      $composableBuilder(column: $table.bookId, builder: (column) => column);

  GeneratedColumn<String> get chapter =>
      $composableBuilder(column: $table.chapter, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get textContent => $composableBuilder(
    column: $table.textContent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$BookHighlightsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BookHighlightsTable,
          BookHighlightRow,
          $$BookHighlightsTableFilterComposer,
          $$BookHighlightsTableOrderingComposer,
          $$BookHighlightsTableAnnotationComposer,
          $$BookHighlightsTableCreateCompanionBuilder,
          $$BookHighlightsTableUpdateCompanionBuilder,
          (
            BookHighlightRow,
            BaseReferences<
              _$AppDatabase,
              $BookHighlightsTable,
              BookHighlightRow
            >,
          ),
          BookHighlightRow,
          PrefetchHooks Function()
        > {
  $$BookHighlightsTableTableManager(
    _$AppDatabase db,
    $BookHighlightsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookHighlightsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookHighlightsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookHighlightsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> bookId = const Value.absent(),
                Value<String?> chapter = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> textContent = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookHighlightsCompanion(
                id: id,
                bookId: bookId,
                chapter: chapter,
                location: location,
                textContent: textContent,
                color: color,
                note: note,
                createdAt: createdAt,
                source: source,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> bookId = const Value.absent(),
                Value<String?> chapter = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> textContent = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookHighlightsCompanion.insert(
                id: id,
                bookId: bookId,
                chapter: chapter,
                location: location,
                textContent: textContent,
                color: color,
                note: note,
                createdAt: createdAt,
                source: source,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BookHighlightsTable, BookHighlightRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $BookHighlightsTable,
                    BookHighlightRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BookHighlightsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BookHighlightsTable,
      BookHighlightRow,
      $$BookHighlightsTableFilterComposer,
      $$BookHighlightsTableOrderingComposer,
      $$BookHighlightsTableAnnotationComposer,
      $$BookHighlightsTableCreateCompanionBuilder,
      $$BookHighlightsTableUpdateCompanionBuilder,
      (
        BookHighlightRow,
        BaseReferences<_$AppDatabase, $BookHighlightsTable, BookHighlightRow>,
      ),
      BookHighlightRow,
      PrefetchHooks Function()
    >;
typedef $$BookBookmarksTableCreateCompanionBuilder =
    BookBookmarksCompanion Function({
      required String id,
      required String bookId,
      required String location,
      Value<String?> note,
      required String createdAt,
      Value<int> rowid,
    });
typedef $$BookBookmarksTableUpdateCompanionBuilder =
    BookBookmarksCompanion Function({
      Value<String> id,
      Value<String> bookId,
      Value<String> location,
      Value<String?> note,
      Value<String> createdAt,
      Value<int> rowid,
    });

class $$BookBookmarksTableFilterComposer
    extends Composer<_$AppDatabase, $BookBookmarksTable> {
  $$BookBookmarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BookBookmarksTableOrderingComposer
    extends Composer<_$AppDatabase, $BookBookmarksTable> {
  $$BookBookmarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BookBookmarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookBookmarksTable> {
  $$BookBookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bookId =>
      $composableBuilder(column: $table.bookId, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$BookBookmarksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BookBookmarksTable,
          BookBookmark,
          $$BookBookmarksTableFilterComposer,
          $$BookBookmarksTableOrderingComposer,
          $$BookBookmarksTableAnnotationComposer,
          $$BookBookmarksTableCreateCompanionBuilder,
          $$BookBookmarksTableUpdateCompanionBuilder,
          (
            BookBookmark,
            BaseReferences<_$AppDatabase, $BookBookmarksTable, BookBookmark>,
          ),
          BookBookmark,
          PrefetchHooks Function()
        > {
  $$BookBookmarksTableTableManager(_$AppDatabase db, $BookBookmarksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookBookmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookBookmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookBookmarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> bookId = const Value.absent(),
                Value<String> location = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookBookmarksCompanion(
                id: id,
                bookId: bookId,
                location: location,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String bookId,
                required String location,
                Value<String?> note = const Value.absent(),
                required String createdAt,
                Value<int> rowid = const Value.absent(),
              }) => BookBookmarksCompanion.insert(
                id: id,
                bookId: bookId,
                location: location,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BookBookmarksTable, BookBookmark>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $BookBookmarksTable,
                    BookBookmark
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BookBookmarksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BookBookmarksTable,
      BookBookmark,
      $$BookBookmarksTableFilterComposer,
      $$BookBookmarksTableOrderingComposer,
      $$BookBookmarksTableAnnotationComposer,
      $$BookBookmarksTableCreateCompanionBuilder,
      $$BookBookmarksTableUpdateCompanionBuilder,
      (
        BookBookmark,
        BaseReferences<_$AppDatabase, $BookBookmarksTable, BookBookmark>,
      ),
      BookBookmark,
      PrefetchHooks Function()
    >;
typedef $$TasksTableCreateCompanionBuilder =
    TasksCompanion Function({
      required String id,
      required String title,
      Value<String> type,
      Value<String?> description,
      Value<String> difficulty,
      Value<String> urgency,
      Value<String> necessity,
      Value<bool> isDone,
      Value<String?> noteId,
      Value<String> subtaskIds,
      Value<String?> reminderTime,
      Value<String?> createdAt,
      Value<String?> completedAt,
      Value<int> rowid,
    });
typedef $$TasksTableUpdateCompanionBuilder =
    TasksCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> type,
      Value<String?> description,
      Value<String> difficulty,
      Value<String> urgency,
      Value<String> necessity,
      Value<bool> isDone,
      Value<String?> noteId,
      Value<String> subtaskIds,
      Value<String?> reminderTime,
      Value<String?> createdAt,
      Value<String?> completedAt,
      Value<int> rowid,
    });

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get urgency => $composableBuilder(
    column: $table.urgency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get necessity => $composableBuilder(
    column: $table.necessity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDone => $composableBuilder(
    column: $table.isDone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get noteId => $composableBuilder(
    column: $table.noteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtaskIds => $composableBuilder(
    column: $table.subtaskIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get urgency => $composableBuilder(
    column: $table.urgency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get necessity => $composableBuilder(
    column: $table.necessity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDone => $composableBuilder(
    column: $table.isDone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get noteId => $composableBuilder(
    column: $table.noteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtaskIds => $composableBuilder(
    column: $table.subtaskIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<String> get urgency =>
      $composableBuilder(column: $table.urgency, builder: (column) => column);

  GeneratedColumn<String> get necessity =>
      $composableBuilder(column: $table.necessity, builder: (column) => column);

  GeneratedColumn<bool> get isDone =>
      $composableBuilder(column: $table.isDone, builder: (column) => column);

  GeneratedColumn<String> get noteId =>
      $composableBuilder(column: $table.noteId, builder: (column) => column);

  GeneratedColumn<String> get subtaskIds => $composableBuilder(
    column: $table.subtaskIds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          TaskRow,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (TaskRow, BaseReferences<_$AppDatabase, $TasksTable, TaskRow>),
          TaskRow,
          PrefetchHooks Function()
        > {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
                Value<String> urgency = const Value.absent(),
                Value<String> necessity = const Value.absent(),
                Value<bool> isDone = const Value.absent(),
                Value<String?> noteId = const Value.absent(),
                Value<String> subtaskIds = const Value.absent(),
                Value<String?> reminderTime = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                title: title,
                type: type,
                description: description,
                difficulty: difficulty,
                urgency: urgency,
                necessity: necessity,
                isDone: isDone,
                noteId: noteId,
                subtaskIds: subtaskIds,
                reminderTime: reminderTime,
                createdAt: createdAt,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String> type = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
                Value<String> urgency = const Value.absent(),
                Value<String> necessity = const Value.absent(),
                Value<bool> isDone = const Value.absent(),
                Value<String?> noteId = const Value.absent(),
                Value<String> subtaskIds = const Value.absent(),
                Value<String?> reminderTime = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                title: title,
                type: type,
                description: description,
                difficulty: difficulty,
                urgency: urgency,
                necessity: necessity,
                isDone: isDone,
                noteId: noteId,
                subtaskIds: subtaskIds,
                reminderTime: reminderTime,
                createdAt: createdAt,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TasksTable, TaskRow>(table),
                  BaseReferences<_$AppDatabase, $TasksTable, TaskRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      TaskRow,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (TaskRow, BaseReferences<_$AppDatabase, $TasksTable, TaskRow>),
      TaskRow,
      PrefetchHooks Function()
    >;
typedef $$PetsTableCreateCompanionBuilder =
    PetsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> level,
      Value<int> exp,
      Value<String> stage,
      Value<int> happiness,
      Value<int> lastFed,
      Value<String?> updatedAt,
    });
typedef $$PetsTableUpdateCompanionBuilder =
    PetsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> level,
      Value<int> exp,
      Value<String> stage,
      Value<int> happiness,
      Value<int> lastFed,
      Value<String?> updatedAt,
    });

class $$PetsTableFilterComposer extends Composer<_$AppDatabase, $PetsTable> {
  $$PetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get exp => $composableBuilder(
    column: $table.exp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get happiness => $composableBuilder(
    column: $table.happiness,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastFed => $composableBuilder(
    column: $table.lastFed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PetsTableOrderingComposer extends Composer<_$AppDatabase, $PetsTable> {
  $$PetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get exp => $composableBuilder(
    column: $table.exp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get happiness => $composableBuilder(
    column: $table.happiness,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastFed => $composableBuilder(
    column: $table.lastFed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PetsTable> {
  $$PetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<int> get exp =>
      $composableBuilder(column: $table.exp, builder: (column) => column);

  GeneratedColumn<String> get stage =>
      $composableBuilder(column: $table.stage, builder: (column) => column);

  GeneratedColumn<int> get happiness =>
      $composableBuilder(column: $table.happiness, builder: (column) => column);

  GeneratedColumn<int> get lastFed =>
      $composableBuilder(column: $table.lastFed, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PetsTable,
          PetRow,
          $$PetsTableFilterComposer,
          $$PetsTableOrderingComposer,
          $$PetsTableAnnotationComposer,
          $$PetsTableCreateCompanionBuilder,
          $$PetsTableUpdateCompanionBuilder,
          (PetRow, BaseReferences<_$AppDatabase, $PetsTable, PetRow>),
          PetRow,
          PrefetchHooks Function()
        > {
  $$PetsTableTableManager(_$AppDatabase db, $PetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<int> exp = const Value.absent(),
                Value<String> stage = const Value.absent(),
                Value<int> happiness = const Value.absent(),
                Value<int> lastFed = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
              }) => PetsCompanion(
                id: id,
                name: name,
                level: level,
                exp: exp,
                stage: stage,
                happiness: happiness,
                lastFed: lastFed,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<int> exp = const Value.absent(),
                Value<String> stage = const Value.absent(),
                Value<int> happiness = const Value.absent(),
                Value<int> lastFed = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
              }) => PetsCompanion.insert(
                id: id,
                name: name,
                level: level,
                exp: exp,
                stage: stage,
                happiness: happiness,
                lastFed: lastFed,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PetsTable, PetRow>(table),
                  BaseReferences<_$AppDatabase, $PetsTable, PetRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PetsTable,
      PetRow,
      $$PetsTableFilterComposer,
      $$PetsTableOrderingComposer,
      $$PetsTableAnnotationComposer,
      $$PetsTableCreateCompanionBuilder,
      $$PetsTableUpdateCompanionBuilder,
      (PetRow, BaseReferences<_$AppDatabase, $PetsTable, PetRow>),
      PetRow,
      PrefetchHooks Function()
    >;
typedef $$UserSettingsTableTableCreateCompanionBuilder =
    UserSettingsTableCompanion Function({
      Value<int> id,
      Value<String> nickname,
      Value<String> bio,
      Value<String> avatarUrl,
      Value<String> themeMode,
      Value<bool> defaultMarkdown,
      Value<int> reviewReminderHour,
      Value<int> reviewReminderMinute,
      Value<int> dailyReviewLimit,
      Value<double> reviewFactor,
      Value<String> heatmapStatMode,
      Value<int> heatmapHighThreshold,
      Value<int> heatmapBurstThreshold,
      Value<int> heatmapWordHighThreshold,
      Value<int> heatmapWordBurstThreshold,
      Value<String> heatmapColorScheme,
      Value<String> heatmapColorLow,
      Value<String> heatmapColorMid,
      Value<String> heatmapColorHigh,
      Value<String> heatmapColorBurst,
      Value<bool> showPet,
      Value<String> petSkin,
      Value<String> petName,
      Value<bool> petInFocusMode,
      Value<int> rawNoteRetentionDays,
      Value<int> dailyWordTarget,
      Value<bool> typewriterSound,
      Value<double> whiteNoiseVolume,
      Value<bool> restReminderOn,
      Value<int> restReminderMinutes,
      Value<String> customNoiseSources,
      Value<int> focusMinutes,
      Value<double> readerFontSize,
      Value<double> readerLineHeight,
      Value<String> readerFontFamily,
      Value<String> readerThemeMode,
      Value<String> readerCustomBg,
      Value<String> readerCustomText,
      Value<String> readerHighlightColor,
      Value<int> readerDailyGoal,
      Value<bool> readerReminderEnabled,
      Value<int> readerReminderInterval,
    });
typedef $$UserSettingsTableTableUpdateCompanionBuilder =
    UserSettingsTableCompanion Function({
      Value<int> id,
      Value<String> nickname,
      Value<String> bio,
      Value<String> avatarUrl,
      Value<String> themeMode,
      Value<bool> defaultMarkdown,
      Value<int> reviewReminderHour,
      Value<int> reviewReminderMinute,
      Value<int> dailyReviewLimit,
      Value<double> reviewFactor,
      Value<String> heatmapStatMode,
      Value<int> heatmapHighThreshold,
      Value<int> heatmapBurstThreshold,
      Value<int> heatmapWordHighThreshold,
      Value<int> heatmapWordBurstThreshold,
      Value<String> heatmapColorScheme,
      Value<String> heatmapColorLow,
      Value<String> heatmapColorMid,
      Value<String> heatmapColorHigh,
      Value<String> heatmapColorBurst,
      Value<bool> showPet,
      Value<String> petSkin,
      Value<String> petName,
      Value<bool> petInFocusMode,
      Value<int> rawNoteRetentionDays,
      Value<int> dailyWordTarget,
      Value<bool> typewriterSound,
      Value<double> whiteNoiseVolume,
      Value<bool> restReminderOn,
      Value<int> restReminderMinutes,
      Value<String> customNoiseSources,
      Value<int> focusMinutes,
      Value<double> readerFontSize,
      Value<double> readerLineHeight,
      Value<String> readerFontFamily,
      Value<String> readerThemeMode,
      Value<String> readerCustomBg,
      Value<String> readerCustomText,
      Value<String> readerHighlightColor,
      Value<int> readerDailyGoal,
      Value<bool> readerReminderEnabled,
      Value<int> readerReminderInterval,
    });

class $$UserSettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $UserSettingsTableTable> {
  $$UserSettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bio => $composableBuilder(
    column: $table.bio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get defaultMarkdown => $composableBuilder(
    column: $table.defaultMarkdown,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewReminderHour => $composableBuilder(
    column: $table.reviewReminderHour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewReminderMinute => $composableBuilder(
    column: $table.reviewReminderMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyReviewLimit => $composableBuilder(
    column: $table.dailyReviewLimit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get reviewFactor => $composableBuilder(
    column: $table.reviewFactor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get heatmapStatMode => $composableBuilder(
    column: $table.heatmapStatMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get heatmapHighThreshold => $composableBuilder(
    column: $table.heatmapHighThreshold,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get heatmapBurstThreshold => $composableBuilder(
    column: $table.heatmapBurstThreshold,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get heatmapWordHighThreshold => $composableBuilder(
    column: $table.heatmapWordHighThreshold,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get heatmapWordBurstThreshold => $composableBuilder(
    column: $table.heatmapWordBurstThreshold,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get heatmapColorScheme => $composableBuilder(
    column: $table.heatmapColorScheme,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get heatmapColorLow => $composableBuilder(
    column: $table.heatmapColorLow,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get heatmapColorMid => $composableBuilder(
    column: $table.heatmapColorMid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get heatmapColorHigh => $composableBuilder(
    column: $table.heatmapColorHigh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get heatmapColorBurst => $composableBuilder(
    column: $table.heatmapColorBurst,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showPet => $composableBuilder(
    column: $table.showPet,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get petSkin => $composableBuilder(
    column: $table.petSkin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get petName => $composableBuilder(
    column: $table.petName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get petInFocusMode => $composableBuilder(
    column: $table.petInFocusMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rawNoteRetentionDays => $composableBuilder(
    column: $table.rawNoteRetentionDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyWordTarget => $composableBuilder(
    column: $table.dailyWordTarget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get typewriterSound => $composableBuilder(
    column: $table.typewriterSound,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get whiteNoiseVolume => $composableBuilder(
    column: $table.whiteNoiseVolume,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get restReminderOn => $composableBuilder(
    column: $table.restReminderOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get restReminderMinutes => $composableBuilder(
    column: $table.restReminderMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customNoiseSources => $composableBuilder(
    column: $table.customNoiseSources,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get focusMinutes => $composableBuilder(
    column: $table.focusMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get readerFontSize => $composableBuilder(
    column: $table.readerFontSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get readerLineHeight => $composableBuilder(
    column: $table.readerLineHeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get readerFontFamily => $composableBuilder(
    column: $table.readerFontFamily,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get readerThemeMode => $composableBuilder(
    column: $table.readerThemeMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get readerCustomBg => $composableBuilder(
    column: $table.readerCustomBg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get readerCustomText => $composableBuilder(
    column: $table.readerCustomText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get readerHighlightColor => $composableBuilder(
    column: $table.readerHighlightColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get readerDailyGoal => $composableBuilder(
    column: $table.readerDailyGoal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get readerReminderEnabled => $composableBuilder(
    column: $table.readerReminderEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get readerReminderInterval => $composableBuilder(
    column: $table.readerReminderInterval,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserSettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $UserSettingsTableTable> {
  $$UserSettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bio => $composableBuilder(
    column: $table.bio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get defaultMarkdown => $composableBuilder(
    column: $table.defaultMarkdown,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewReminderHour => $composableBuilder(
    column: $table.reviewReminderHour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewReminderMinute => $composableBuilder(
    column: $table.reviewReminderMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyReviewLimit => $composableBuilder(
    column: $table.dailyReviewLimit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get reviewFactor => $composableBuilder(
    column: $table.reviewFactor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get heatmapStatMode => $composableBuilder(
    column: $table.heatmapStatMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get heatmapHighThreshold => $composableBuilder(
    column: $table.heatmapHighThreshold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get heatmapBurstThreshold => $composableBuilder(
    column: $table.heatmapBurstThreshold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get heatmapWordHighThreshold => $composableBuilder(
    column: $table.heatmapWordHighThreshold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get heatmapWordBurstThreshold => $composableBuilder(
    column: $table.heatmapWordBurstThreshold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get heatmapColorScheme => $composableBuilder(
    column: $table.heatmapColorScheme,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get heatmapColorLow => $composableBuilder(
    column: $table.heatmapColorLow,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get heatmapColorMid => $composableBuilder(
    column: $table.heatmapColorMid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get heatmapColorHigh => $composableBuilder(
    column: $table.heatmapColorHigh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get heatmapColorBurst => $composableBuilder(
    column: $table.heatmapColorBurst,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showPet => $composableBuilder(
    column: $table.showPet,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get petSkin => $composableBuilder(
    column: $table.petSkin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get petName => $composableBuilder(
    column: $table.petName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get petInFocusMode => $composableBuilder(
    column: $table.petInFocusMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rawNoteRetentionDays => $composableBuilder(
    column: $table.rawNoteRetentionDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyWordTarget => $composableBuilder(
    column: $table.dailyWordTarget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get typewriterSound => $composableBuilder(
    column: $table.typewriterSound,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get whiteNoiseVolume => $composableBuilder(
    column: $table.whiteNoiseVolume,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get restReminderOn => $composableBuilder(
    column: $table.restReminderOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get restReminderMinutes => $composableBuilder(
    column: $table.restReminderMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customNoiseSources => $composableBuilder(
    column: $table.customNoiseSources,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get focusMinutes => $composableBuilder(
    column: $table.focusMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get readerFontSize => $composableBuilder(
    column: $table.readerFontSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get readerLineHeight => $composableBuilder(
    column: $table.readerLineHeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get readerFontFamily => $composableBuilder(
    column: $table.readerFontFamily,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get readerThemeMode => $composableBuilder(
    column: $table.readerThemeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get readerCustomBg => $composableBuilder(
    column: $table.readerCustomBg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get readerCustomText => $composableBuilder(
    column: $table.readerCustomText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get readerHighlightColor => $composableBuilder(
    column: $table.readerHighlightColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get readerDailyGoal => $composableBuilder(
    column: $table.readerDailyGoal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get readerReminderEnabled => $composableBuilder(
    column: $table.readerReminderEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get readerReminderInterval => $composableBuilder(
    column: $table.readerReminderInterval,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserSettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserSettingsTableTable> {
  $$UserSettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nickname =>
      $composableBuilder(column: $table.nickname, builder: (column) => column);

  GeneratedColumn<String> get bio =>
      $composableBuilder(column: $table.bio, builder: (column) => column);

  GeneratedColumn<String> get avatarUrl =>
      $composableBuilder(column: $table.avatarUrl, builder: (column) => column);

  GeneratedColumn<String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<bool> get defaultMarkdown => $composableBuilder(
    column: $table.defaultMarkdown,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reviewReminderHour => $composableBuilder(
    column: $table.reviewReminderHour,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reviewReminderMinute => $composableBuilder(
    column: $table.reviewReminderMinute,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dailyReviewLimit => $composableBuilder(
    column: $table.dailyReviewLimit,
    builder: (column) => column,
  );

  GeneratedColumn<double> get reviewFactor => $composableBuilder(
    column: $table.reviewFactor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get heatmapStatMode => $composableBuilder(
    column: $table.heatmapStatMode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get heatmapHighThreshold => $composableBuilder(
    column: $table.heatmapHighThreshold,
    builder: (column) => column,
  );

  GeneratedColumn<int> get heatmapBurstThreshold => $composableBuilder(
    column: $table.heatmapBurstThreshold,
    builder: (column) => column,
  );

  GeneratedColumn<int> get heatmapWordHighThreshold => $composableBuilder(
    column: $table.heatmapWordHighThreshold,
    builder: (column) => column,
  );

  GeneratedColumn<int> get heatmapWordBurstThreshold => $composableBuilder(
    column: $table.heatmapWordBurstThreshold,
    builder: (column) => column,
  );

  GeneratedColumn<String> get heatmapColorScheme => $composableBuilder(
    column: $table.heatmapColorScheme,
    builder: (column) => column,
  );

  GeneratedColumn<String> get heatmapColorLow => $composableBuilder(
    column: $table.heatmapColorLow,
    builder: (column) => column,
  );

  GeneratedColumn<String> get heatmapColorMid => $composableBuilder(
    column: $table.heatmapColorMid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get heatmapColorHigh => $composableBuilder(
    column: $table.heatmapColorHigh,
    builder: (column) => column,
  );

  GeneratedColumn<String> get heatmapColorBurst => $composableBuilder(
    column: $table.heatmapColorBurst,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showPet =>
      $composableBuilder(column: $table.showPet, builder: (column) => column);

  GeneratedColumn<String> get petSkin =>
      $composableBuilder(column: $table.petSkin, builder: (column) => column);

  GeneratedColumn<String> get petName =>
      $composableBuilder(column: $table.petName, builder: (column) => column);

  GeneratedColumn<bool> get petInFocusMode => $composableBuilder(
    column: $table.petInFocusMode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rawNoteRetentionDays => $composableBuilder(
    column: $table.rawNoteRetentionDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dailyWordTarget => $composableBuilder(
    column: $table.dailyWordTarget,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get typewriterSound => $composableBuilder(
    column: $table.typewriterSound,
    builder: (column) => column,
  );

  GeneratedColumn<double> get whiteNoiseVolume => $composableBuilder(
    column: $table.whiteNoiseVolume,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get restReminderOn => $composableBuilder(
    column: $table.restReminderOn,
    builder: (column) => column,
  );

  GeneratedColumn<int> get restReminderMinutes => $composableBuilder(
    column: $table.restReminderMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customNoiseSources => $composableBuilder(
    column: $table.customNoiseSources,
    builder: (column) => column,
  );

  GeneratedColumn<int> get focusMinutes => $composableBuilder(
    column: $table.focusMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<double> get readerFontSize => $composableBuilder(
    column: $table.readerFontSize,
    builder: (column) => column,
  );

  GeneratedColumn<double> get readerLineHeight => $composableBuilder(
    column: $table.readerLineHeight,
    builder: (column) => column,
  );

  GeneratedColumn<String> get readerFontFamily => $composableBuilder(
    column: $table.readerFontFamily,
    builder: (column) => column,
  );

  GeneratedColumn<String> get readerThemeMode => $composableBuilder(
    column: $table.readerThemeMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get readerCustomBg => $composableBuilder(
    column: $table.readerCustomBg,
    builder: (column) => column,
  );

  GeneratedColumn<String> get readerCustomText => $composableBuilder(
    column: $table.readerCustomText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get readerHighlightColor => $composableBuilder(
    column: $table.readerHighlightColor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get readerDailyGoal => $composableBuilder(
    column: $table.readerDailyGoal,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get readerReminderEnabled => $composableBuilder(
    column: $table.readerReminderEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get readerReminderInterval => $composableBuilder(
    column: $table.readerReminderInterval,
    builder: (column) => column,
  );
}

class $$UserSettingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserSettingsTableTable,
          UserSettingsTableData,
          $$UserSettingsTableTableFilterComposer,
          $$UserSettingsTableTableOrderingComposer,
          $$UserSettingsTableTableAnnotationComposer,
          $$UserSettingsTableTableCreateCompanionBuilder,
          $$UserSettingsTableTableUpdateCompanionBuilder,
          (
            UserSettingsTableData,
            BaseReferences<
              _$AppDatabase,
              $UserSettingsTableTable,
              UserSettingsTableData
            >,
          ),
          UserSettingsTableData,
          PrefetchHooks Function()
        > {
  $$UserSettingsTableTableTableManager(
    _$AppDatabase db,
    $UserSettingsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserSettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserSettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserSettingsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> nickname = const Value.absent(),
                Value<String> bio = const Value.absent(),
                Value<String> avatarUrl = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<bool> defaultMarkdown = const Value.absent(),
                Value<int> reviewReminderHour = const Value.absent(),
                Value<int> reviewReminderMinute = const Value.absent(),
                Value<int> dailyReviewLimit = const Value.absent(),
                Value<double> reviewFactor = const Value.absent(),
                Value<String> heatmapStatMode = const Value.absent(),
                Value<int> heatmapHighThreshold = const Value.absent(),
                Value<int> heatmapBurstThreshold = const Value.absent(),
                Value<int> heatmapWordHighThreshold = const Value.absent(),
                Value<int> heatmapWordBurstThreshold = const Value.absent(),
                Value<String> heatmapColorScheme = const Value.absent(),
                Value<String> heatmapColorLow = const Value.absent(),
                Value<String> heatmapColorMid = const Value.absent(),
                Value<String> heatmapColorHigh = const Value.absent(),
                Value<String> heatmapColorBurst = const Value.absent(),
                Value<bool> showPet = const Value.absent(),
                Value<String> petSkin = const Value.absent(),
                Value<String> petName = const Value.absent(),
                Value<bool> petInFocusMode = const Value.absent(),
                Value<int> rawNoteRetentionDays = const Value.absent(),
                Value<int> dailyWordTarget = const Value.absent(),
                Value<bool> typewriterSound = const Value.absent(),
                Value<double> whiteNoiseVolume = const Value.absent(),
                Value<bool> restReminderOn = const Value.absent(),
                Value<int> restReminderMinutes = const Value.absent(),
                Value<String> customNoiseSources = const Value.absent(),
                Value<int> focusMinutes = const Value.absent(),
                Value<double> readerFontSize = const Value.absent(),
                Value<double> readerLineHeight = const Value.absent(),
                Value<String> readerFontFamily = const Value.absent(),
                Value<String> readerThemeMode = const Value.absent(),
                Value<String> readerCustomBg = const Value.absent(),
                Value<String> readerCustomText = const Value.absent(),
                Value<String> readerHighlightColor = const Value.absent(),
                Value<int> readerDailyGoal = const Value.absent(),
                Value<bool> readerReminderEnabled = const Value.absent(),
                Value<int> readerReminderInterval = const Value.absent(),
              }) => UserSettingsTableCompanion(
                id: id,
                nickname: nickname,
                bio: bio,
                avatarUrl: avatarUrl,
                themeMode: themeMode,
                defaultMarkdown: defaultMarkdown,
                reviewReminderHour: reviewReminderHour,
                reviewReminderMinute: reviewReminderMinute,
                dailyReviewLimit: dailyReviewLimit,
                reviewFactor: reviewFactor,
                heatmapStatMode: heatmapStatMode,
                heatmapHighThreshold: heatmapHighThreshold,
                heatmapBurstThreshold: heatmapBurstThreshold,
                heatmapWordHighThreshold: heatmapWordHighThreshold,
                heatmapWordBurstThreshold: heatmapWordBurstThreshold,
                heatmapColorScheme: heatmapColorScheme,
                heatmapColorLow: heatmapColorLow,
                heatmapColorMid: heatmapColorMid,
                heatmapColorHigh: heatmapColorHigh,
                heatmapColorBurst: heatmapColorBurst,
                showPet: showPet,
                petSkin: petSkin,
                petName: petName,
                petInFocusMode: petInFocusMode,
                rawNoteRetentionDays: rawNoteRetentionDays,
                dailyWordTarget: dailyWordTarget,
                typewriterSound: typewriterSound,
                whiteNoiseVolume: whiteNoiseVolume,
                restReminderOn: restReminderOn,
                restReminderMinutes: restReminderMinutes,
                customNoiseSources: customNoiseSources,
                focusMinutes: focusMinutes,
                readerFontSize: readerFontSize,
                readerLineHeight: readerLineHeight,
                readerFontFamily: readerFontFamily,
                readerThemeMode: readerThemeMode,
                readerCustomBg: readerCustomBg,
                readerCustomText: readerCustomText,
                readerHighlightColor: readerHighlightColor,
                readerDailyGoal: readerDailyGoal,
                readerReminderEnabled: readerReminderEnabled,
                readerReminderInterval: readerReminderInterval,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> nickname = const Value.absent(),
                Value<String> bio = const Value.absent(),
                Value<String> avatarUrl = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<bool> defaultMarkdown = const Value.absent(),
                Value<int> reviewReminderHour = const Value.absent(),
                Value<int> reviewReminderMinute = const Value.absent(),
                Value<int> dailyReviewLimit = const Value.absent(),
                Value<double> reviewFactor = const Value.absent(),
                Value<String> heatmapStatMode = const Value.absent(),
                Value<int> heatmapHighThreshold = const Value.absent(),
                Value<int> heatmapBurstThreshold = const Value.absent(),
                Value<int> heatmapWordHighThreshold = const Value.absent(),
                Value<int> heatmapWordBurstThreshold = const Value.absent(),
                Value<String> heatmapColorScheme = const Value.absent(),
                Value<String> heatmapColorLow = const Value.absent(),
                Value<String> heatmapColorMid = const Value.absent(),
                Value<String> heatmapColorHigh = const Value.absent(),
                Value<String> heatmapColorBurst = const Value.absent(),
                Value<bool> showPet = const Value.absent(),
                Value<String> petSkin = const Value.absent(),
                Value<String> petName = const Value.absent(),
                Value<bool> petInFocusMode = const Value.absent(),
                Value<int> rawNoteRetentionDays = const Value.absent(),
                Value<int> dailyWordTarget = const Value.absent(),
                Value<bool> typewriterSound = const Value.absent(),
                Value<double> whiteNoiseVolume = const Value.absent(),
                Value<bool> restReminderOn = const Value.absent(),
                Value<int> restReminderMinutes = const Value.absent(),
                Value<String> customNoiseSources = const Value.absent(),
                Value<int> focusMinutes = const Value.absent(),
                Value<double> readerFontSize = const Value.absent(),
                Value<double> readerLineHeight = const Value.absent(),
                Value<String> readerFontFamily = const Value.absent(),
                Value<String> readerThemeMode = const Value.absent(),
                Value<String> readerCustomBg = const Value.absent(),
                Value<String> readerCustomText = const Value.absent(),
                Value<String> readerHighlightColor = const Value.absent(),
                Value<int> readerDailyGoal = const Value.absent(),
                Value<bool> readerReminderEnabled = const Value.absent(),
                Value<int> readerReminderInterval = const Value.absent(),
              }) => UserSettingsTableCompanion.insert(
                id: id,
                nickname: nickname,
                bio: bio,
                avatarUrl: avatarUrl,
                themeMode: themeMode,
                defaultMarkdown: defaultMarkdown,
                reviewReminderHour: reviewReminderHour,
                reviewReminderMinute: reviewReminderMinute,
                dailyReviewLimit: dailyReviewLimit,
                reviewFactor: reviewFactor,
                heatmapStatMode: heatmapStatMode,
                heatmapHighThreshold: heatmapHighThreshold,
                heatmapBurstThreshold: heatmapBurstThreshold,
                heatmapWordHighThreshold: heatmapWordHighThreshold,
                heatmapWordBurstThreshold: heatmapWordBurstThreshold,
                heatmapColorScheme: heatmapColorScheme,
                heatmapColorLow: heatmapColorLow,
                heatmapColorMid: heatmapColorMid,
                heatmapColorHigh: heatmapColorHigh,
                heatmapColorBurst: heatmapColorBurst,
                showPet: showPet,
                petSkin: petSkin,
                petName: petName,
                petInFocusMode: petInFocusMode,
                rawNoteRetentionDays: rawNoteRetentionDays,
                dailyWordTarget: dailyWordTarget,
                typewriterSound: typewriterSound,
                whiteNoiseVolume: whiteNoiseVolume,
                restReminderOn: restReminderOn,
                restReminderMinutes: restReminderMinutes,
                customNoiseSources: customNoiseSources,
                focusMinutes: focusMinutes,
                readerFontSize: readerFontSize,
                readerLineHeight: readerLineHeight,
                readerFontFamily: readerFontFamily,
                readerThemeMode: readerThemeMode,
                readerCustomBg: readerCustomBg,
                readerCustomText: readerCustomText,
                readerHighlightColor: readerHighlightColor,
                readerDailyGoal: readerDailyGoal,
                readerReminderEnabled: readerReminderEnabled,
                readerReminderInterval: readerReminderInterval,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UserSettingsTableTable, UserSettingsTableData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $UserSettingsTableTable,
                    UserSettingsTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserSettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserSettingsTableTable,
      UserSettingsTableData,
      $$UserSettingsTableTableFilterComposer,
      $$UserSettingsTableTableOrderingComposer,
      $$UserSettingsTableTableAnnotationComposer,
      $$UserSettingsTableTableCreateCompanionBuilder,
      $$UserSettingsTableTableUpdateCompanionBuilder,
      (
        UserSettingsTableData,
        BaseReferences<
          _$AppDatabase,
          $UserSettingsTableTable,
          UserSettingsTableData
        >,
      ),
      UserSettingsTableData,
      PrefetchHooks Function()
    >;
typedef $$IsbnCacheTableCreateCompanionBuilder =
    IsbnCacheCompanion Function({
      required String isbn,
      Value<String?> title,
      Value<String?> author,
      Value<String?> coverUrl,
      Value<String?> source,
      Value<String?> updatedAt,
      Value<int> rowid,
    });
typedef $$IsbnCacheTableUpdateCompanionBuilder =
    IsbnCacheCompanion Function({
      Value<String> isbn,
      Value<String?> title,
      Value<String?> author,
      Value<String?> coverUrl,
      Value<String?> source,
      Value<String?> updatedAt,
      Value<int> rowid,
    });

class $$IsbnCacheTableFilterComposer
    extends Composer<_$AppDatabase, $IsbnCacheTable> {
  $$IsbnCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get isbn => $composableBuilder(
    column: $table.isbn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IsbnCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $IsbnCacheTable> {
  $$IsbnCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get isbn => $composableBuilder(
    column: $table.isbn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IsbnCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $IsbnCacheTable> {
  $$IsbnCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get isbn =>
      $composableBuilder(column: $table.isbn, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$IsbnCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IsbnCacheTable,
          IsbnCacheData,
          $$IsbnCacheTableFilterComposer,
          $$IsbnCacheTableOrderingComposer,
          $$IsbnCacheTableAnnotationComposer,
          $$IsbnCacheTableCreateCompanionBuilder,
          $$IsbnCacheTableUpdateCompanionBuilder,
          (
            IsbnCacheData,
            BaseReferences<_$AppDatabase, $IsbnCacheTable, IsbnCacheData>,
          ),
          IsbnCacheData,
          PrefetchHooks Function()
        > {
  $$IsbnCacheTableTableManager(_$AppDatabase db, $IsbnCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IsbnCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IsbnCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IsbnCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> isbn = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IsbnCacheCompanion(
                isbn: isbn,
                title: title,
                author: author,
                coverUrl: coverUrl,
                source: source,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String isbn,
                Value<String?> title = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IsbnCacheCompanion.insert(
                isbn: isbn,
                title: title,
                author: author,
                coverUrl: coverUrl,
                source: source,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$IsbnCacheTable, IsbnCacheData>(table),
                  BaseReferences<_$AppDatabase, $IsbnCacheTable, IsbnCacheData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IsbnCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IsbnCacheTable,
      IsbnCacheData,
      $$IsbnCacheTableFilterComposer,
      $$IsbnCacheTableOrderingComposer,
      $$IsbnCacheTableAnnotationComposer,
      $$IsbnCacheTableCreateCompanionBuilder,
      $$IsbnCacheTableUpdateCompanionBuilder,
      (
        IsbnCacheData,
        BaseReferences<_$AppDatabase, $IsbnCacheTable, IsbnCacheData>,
      ),
      IsbnCacheData,
      PrefetchHooks Function()
    >;
typedef $$PdfDrawingsTableCreateCompanionBuilder =
    PdfDrawingsCompanion Function({
      required String id,
      Value<String?> bookId,
      Value<int?> page,
      Value<String?> points,
      Value<String?> color,
      Value<String?> createdAt,
      Value<int> rowid,
    });
typedef $$PdfDrawingsTableUpdateCompanionBuilder =
    PdfDrawingsCompanion Function({
      Value<String> id,
      Value<String?> bookId,
      Value<int?> page,
      Value<String?> points,
      Value<String?> color,
      Value<String?> createdAt,
      Value<int> rowid,
    });

class $$PdfDrawingsTableFilterComposer
    extends Composer<_$AppDatabase, $PdfDrawingsTable> {
  $$PdfDrawingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PdfDrawingsTableOrderingComposer
    extends Composer<_$AppDatabase, $PdfDrawingsTable> {
  $$PdfDrawingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PdfDrawingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PdfDrawingsTable> {
  $$PdfDrawingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bookId =>
      $composableBuilder(column: $table.bookId, builder: (column) => column);

  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<String> get points =>
      $composableBuilder(column: $table.points, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PdfDrawingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PdfDrawingsTable,
          PdfDrawingRow,
          $$PdfDrawingsTableFilterComposer,
          $$PdfDrawingsTableOrderingComposer,
          $$PdfDrawingsTableAnnotationComposer,
          $$PdfDrawingsTableCreateCompanionBuilder,
          $$PdfDrawingsTableUpdateCompanionBuilder,
          (
            PdfDrawingRow,
            BaseReferences<_$AppDatabase, $PdfDrawingsTable, PdfDrawingRow>,
          ),
          PdfDrawingRow,
          PrefetchHooks Function()
        > {
  $$PdfDrawingsTableTableManager(_$AppDatabase db, $PdfDrawingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PdfDrawingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PdfDrawingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PdfDrawingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> bookId = const Value.absent(),
                Value<int?> page = const Value.absent(),
                Value<String?> points = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PdfDrawingsCompanion(
                id: id,
                bookId: bookId,
                page: page,
                points: points,
                color: color,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> bookId = const Value.absent(),
                Value<int?> page = const Value.absent(),
                Value<String?> points = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PdfDrawingsCompanion.insert(
                id: id,
                bookId: bookId,
                page: page,
                points: points,
                color: color,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PdfDrawingsTable, PdfDrawingRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PdfDrawingsTable,
                    PdfDrawingRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PdfDrawingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PdfDrawingsTable,
      PdfDrawingRow,
      $$PdfDrawingsTableFilterComposer,
      $$PdfDrawingsTableOrderingComposer,
      $$PdfDrawingsTableAnnotationComposer,
      $$PdfDrawingsTableCreateCompanionBuilder,
      $$PdfDrawingsTableUpdateCompanionBuilder,
      (
        PdfDrawingRow,
        BaseReferences<_$AppDatabase, $PdfDrawingsTable, PdfDrawingRow>,
      ),
      PdfDrawingRow,
      PrefetchHooks Function()
    >;
typedef $$BoardViewsTableCreateCompanionBuilder =
    BoardViewsCompanion Function({
      required String id,
      Value<String?> name,
      Value<String?> type,
      Value<String?> ownerId,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<int> rowid,
    });
typedef $$BoardViewsTableUpdateCompanionBuilder =
    BoardViewsCompanion Function({
      Value<String> id,
      Value<String?> name,
      Value<String?> type,
      Value<String?> ownerId,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<int> rowid,
    });

class $$BoardViewsTableFilterComposer
    extends Composer<_$AppDatabase, $BoardViewsTable> {
  $$BoardViewsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BoardViewsTableOrderingComposer
    extends Composer<_$AppDatabase, $BoardViewsTable> {
  $$BoardViewsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BoardViewsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BoardViewsTable> {
  $$BoardViewsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BoardViewsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BoardViewsTable,
          BoardView,
          $$BoardViewsTableFilterComposer,
          $$BoardViewsTableOrderingComposer,
          $$BoardViewsTableAnnotationComposer,
          $$BoardViewsTableCreateCompanionBuilder,
          $$BoardViewsTableUpdateCompanionBuilder,
          (
            BoardView,
            BaseReferences<_$AppDatabase, $BoardViewsTable, BoardView>,
          ),
          BoardView,
          PrefetchHooks Function()
        > {
  $$BoardViewsTableTableManager(_$AppDatabase db, $BoardViewsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BoardViewsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BoardViewsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BoardViewsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> type = const Value.absent(),
                Value<String?> ownerId = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BoardViewsCompanion(
                id: id,
                name: name,
                type: type,
                ownerId: ownerId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> name = const Value.absent(),
                Value<String?> type = const Value.absent(),
                Value<String?> ownerId = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BoardViewsCompanion.insert(
                id: id,
                name: name,
                type: type,
                ownerId: ownerId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BoardViewsTable, BoardView>(table),
                  BaseReferences<_$AppDatabase, $BoardViewsTable, BoardView>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BoardViewsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BoardViewsTable,
      BoardView,
      $$BoardViewsTableFilterComposer,
      $$BoardViewsTableOrderingComposer,
      $$BoardViewsTableAnnotationComposer,
      $$BoardViewsTableCreateCompanionBuilder,
      $$BoardViewsTableUpdateCompanionBuilder,
      (BoardView, BaseReferences<_$AppDatabase, $BoardViewsTable, BoardView>),
      BoardView,
      PrefetchHooks Function()
    >;
typedef $$BoardNodesTableCreateCompanionBuilder =
    BoardNodesCompanion Function({
      required String id,
      Value<String?> viewId,
      Value<String?> cardId,
      Value<String> type,
      Value<String?> noteId,
      Value<double?> x,
      Value<double?> y,
      Value<int?> zIndex,
      Value<int> rowid,
    });
typedef $$BoardNodesTableUpdateCompanionBuilder =
    BoardNodesCompanion Function({
      Value<String> id,
      Value<String?> viewId,
      Value<String?> cardId,
      Value<String> type,
      Value<String?> noteId,
      Value<double?> x,
      Value<double?> y,
      Value<int?> zIndex,
      Value<int> rowid,
    });

class $$BoardNodesTableFilterComposer
    extends Composer<_$AppDatabase, $BoardNodesTable> {
  $$BoardNodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get viewId => $composableBuilder(
    column: $table.viewId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get noteId => $composableBuilder(
    column: $table.noteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get zIndex => $composableBuilder(
    column: $table.zIndex,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BoardNodesTableOrderingComposer
    extends Composer<_$AppDatabase, $BoardNodesTable> {
  $$BoardNodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get viewId => $composableBuilder(
    column: $table.viewId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get noteId => $composableBuilder(
    column: $table.noteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get zIndex => $composableBuilder(
    column: $table.zIndex,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BoardNodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BoardNodesTable> {
  $$BoardNodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get viewId =>
      $composableBuilder(column: $table.viewId, builder: (column) => column);

  GeneratedColumn<String> get cardId =>
      $composableBuilder(column: $table.cardId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get noteId =>
      $composableBuilder(column: $table.noteId, builder: (column) => column);

  GeneratedColumn<double> get x =>
      $composableBuilder(column: $table.x, builder: (column) => column);

  GeneratedColumn<double> get y =>
      $composableBuilder(column: $table.y, builder: (column) => column);

  GeneratedColumn<int> get zIndex =>
      $composableBuilder(column: $table.zIndex, builder: (column) => column);
}

class $$BoardNodesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BoardNodesTable,
          BoardNode,
          $$BoardNodesTableFilterComposer,
          $$BoardNodesTableOrderingComposer,
          $$BoardNodesTableAnnotationComposer,
          $$BoardNodesTableCreateCompanionBuilder,
          $$BoardNodesTableUpdateCompanionBuilder,
          (
            BoardNode,
            BaseReferences<_$AppDatabase, $BoardNodesTable, BoardNode>,
          ),
          BoardNode,
          PrefetchHooks Function()
        > {
  $$BoardNodesTableTableManager(_$AppDatabase db, $BoardNodesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BoardNodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BoardNodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BoardNodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> viewId = const Value.absent(),
                Value<String?> cardId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> noteId = const Value.absent(),
                Value<double?> x = const Value.absent(),
                Value<double?> y = const Value.absent(),
                Value<int?> zIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BoardNodesCompanion(
                id: id,
                viewId: viewId,
                cardId: cardId,
                type: type,
                noteId: noteId,
                x: x,
                y: y,
                zIndex: zIndex,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> viewId = const Value.absent(),
                Value<String?> cardId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> noteId = const Value.absent(),
                Value<double?> x = const Value.absent(),
                Value<double?> y = const Value.absent(),
                Value<int?> zIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BoardNodesCompanion.insert(
                id: id,
                viewId: viewId,
                cardId: cardId,
                type: type,
                noteId: noteId,
                x: x,
                y: y,
                zIndex: zIndex,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BoardNodesTable, BoardNode>(table),
                  BaseReferences<_$AppDatabase, $BoardNodesTable, BoardNode>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BoardNodesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BoardNodesTable,
      BoardNode,
      $$BoardNodesTableFilterComposer,
      $$BoardNodesTableOrderingComposer,
      $$BoardNodesTableAnnotationComposer,
      $$BoardNodesTableCreateCompanionBuilder,
      $$BoardNodesTableUpdateCompanionBuilder,
      (BoardNode, BaseReferences<_$AppDatabase, $BoardNodesTable, BoardNode>),
      BoardNode,
      PrefetchHooks Function()
    >;
typedef $$BoardEdgesTableCreateCompanionBuilder =
    BoardEdgesCompanion Function({
      required String id,
      Value<String?> viewId,
      Value<String?> sourceNodeId,
      Value<String?> targetNodeId,
      Value<int> rowid,
    });
typedef $$BoardEdgesTableUpdateCompanionBuilder =
    BoardEdgesCompanion Function({
      Value<String> id,
      Value<String?> viewId,
      Value<String?> sourceNodeId,
      Value<String?> targetNodeId,
      Value<int> rowid,
    });

class $$BoardEdgesTableFilterComposer
    extends Composer<_$AppDatabase, $BoardEdgesTable> {
  $$BoardEdgesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get viewId => $composableBuilder(
    column: $table.viewId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceNodeId => $composableBuilder(
    column: $table.sourceNodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetNodeId => $composableBuilder(
    column: $table.targetNodeId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BoardEdgesTableOrderingComposer
    extends Composer<_$AppDatabase, $BoardEdgesTable> {
  $$BoardEdgesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get viewId => $composableBuilder(
    column: $table.viewId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceNodeId => $composableBuilder(
    column: $table.sourceNodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetNodeId => $composableBuilder(
    column: $table.targetNodeId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BoardEdgesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BoardEdgesTable> {
  $$BoardEdgesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get viewId =>
      $composableBuilder(column: $table.viewId, builder: (column) => column);

  GeneratedColumn<String> get sourceNodeId => $composableBuilder(
    column: $table.sourceNodeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetNodeId => $composableBuilder(
    column: $table.targetNodeId,
    builder: (column) => column,
  );
}

class $$BoardEdgesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BoardEdgesTable,
          BoardEdge,
          $$BoardEdgesTableFilterComposer,
          $$BoardEdgesTableOrderingComposer,
          $$BoardEdgesTableAnnotationComposer,
          $$BoardEdgesTableCreateCompanionBuilder,
          $$BoardEdgesTableUpdateCompanionBuilder,
          (
            BoardEdge,
            BaseReferences<_$AppDatabase, $BoardEdgesTable, BoardEdge>,
          ),
          BoardEdge,
          PrefetchHooks Function()
        > {
  $$BoardEdgesTableTableManager(_$AppDatabase db, $BoardEdgesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BoardEdgesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BoardEdgesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BoardEdgesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> viewId = const Value.absent(),
                Value<String?> sourceNodeId = const Value.absent(),
                Value<String?> targetNodeId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BoardEdgesCompanion(
                id: id,
                viewId: viewId,
                sourceNodeId: sourceNodeId,
                targetNodeId: targetNodeId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> viewId = const Value.absent(),
                Value<String?> sourceNodeId = const Value.absent(),
                Value<String?> targetNodeId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BoardEdgesCompanion.insert(
                id: id,
                viewId: viewId,
                sourceNodeId: sourceNodeId,
                targetNodeId: targetNodeId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BoardEdgesTable, BoardEdge>(table),
                  BaseReferences<_$AppDatabase, $BoardEdgesTable, BoardEdge>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BoardEdgesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BoardEdgesTable,
      BoardEdge,
      $$BoardEdgesTableFilterComposer,
      $$BoardEdgesTableOrderingComposer,
      $$BoardEdgesTableAnnotationComposer,
      $$BoardEdgesTableCreateCompanionBuilder,
      $$BoardEdgesTableUpdateCompanionBuilder,
      (BoardEdge, BaseReferences<_$AppDatabase, $BoardEdgesTable, BoardEdge>),
      BoardEdge,
      PrefetchHooks Function()
    >;
typedef $$BoardGroupsTableCreateCompanionBuilder =
    BoardGroupsCompanion Function({
      required String id,
      Value<String?> viewId,
      Value<String?> nodeIds,
      Value<String?> color,
      Value<int> rowid,
    });
typedef $$BoardGroupsTableUpdateCompanionBuilder =
    BoardGroupsCompanion Function({
      Value<String> id,
      Value<String?> viewId,
      Value<String?> nodeIds,
      Value<String?> color,
      Value<int> rowid,
    });

class $$BoardGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $BoardGroupsTable> {
  $$BoardGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get viewId => $composableBuilder(
    column: $table.viewId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nodeIds => $composableBuilder(
    column: $table.nodeIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BoardGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $BoardGroupsTable> {
  $$BoardGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get viewId => $composableBuilder(
    column: $table.viewId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nodeIds => $composableBuilder(
    column: $table.nodeIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BoardGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BoardGroupsTable> {
  $$BoardGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get viewId =>
      $composableBuilder(column: $table.viewId, builder: (column) => column);

  GeneratedColumn<String> get nodeIds =>
      $composableBuilder(column: $table.nodeIds, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);
}

class $$BoardGroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BoardGroupsTable,
          BoardGroup,
          $$BoardGroupsTableFilterComposer,
          $$BoardGroupsTableOrderingComposer,
          $$BoardGroupsTableAnnotationComposer,
          $$BoardGroupsTableCreateCompanionBuilder,
          $$BoardGroupsTableUpdateCompanionBuilder,
          (
            BoardGroup,
            BaseReferences<_$AppDatabase, $BoardGroupsTable, BoardGroup>,
          ),
          BoardGroup,
          PrefetchHooks Function()
        > {
  $$BoardGroupsTableTableManager(_$AppDatabase db, $BoardGroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BoardGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BoardGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BoardGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> viewId = const Value.absent(),
                Value<String?> nodeIds = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BoardGroupsCompanion(
                id: id,
                viewId: viewId,
                nodeIds: nodeIds,
                color: color,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> viewId = const Value.absent(),
                Value<String?> nodeIds = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BoardGroupsCompanion.insert(
                id: id,
                viewId: viewId,
                nodeIds: nodeIds,
                color: color,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BoardGroupsTable, BoardGroup>(table),
                  BaseReferences<_$AppDatabase, $BoardGroupsTable, BoardGroup>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BoardGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BoardGroupsTable,
      BoardGroup,
      $$BoardGroupsTableFilterComposer,
      $$BoardGroupsTableOrderingComposer,
      $$BoardGroupsTableAnnotationComposer,
      $$BoardGroupsTableCreateCompanionBuilder,
      $$BoardGroupsTableUpdateCompanionBuilder,
      (
        BoardGroup,
        BaseReferences<_$AppDatabase, $BoardGroupsTable, BoardGroup>,
      ),
      BoardGroup,
      PrefetchHooks Function()
    >;
typedef $$BoardTextsTableCreateCompanionBuilder =
    BoardTextsCompanion Function({
      required String id,
      Value<String?> viewId,
      Value<double?> x,
      Value<double?> y,
      Value<String?> content,
      Value<int> rowid,
    });
typedef $$BoardTextsTableUpdateCompanionBuilder =
    BoardTextsCompanion Function({
      Value<String> id,
      Value<String?> viewId,
      Value<double?> x,
      Value<double?> y,
      Value<String?> content,
      Value<int> rowid,
    });

class $$BoardTextsTableFilterComposer
    extends Composer<_$AppDatabase, $BoardTextsTable> {
  $$BoardTextsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get viewId => $composableBuilder(
    column: $table.viewId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BoardTextsTableOrderingComposer
    extends Composer<_$AppDatabase, $BoardTextsTable> {
  $$BoardTextsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get viewId => $composableBuilder(
    column: $table.viewId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BoardTextsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BoardTextsTable> {
  $$BoardTextsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get viewId =>
      $composableBuilder(column: $table.viewId, builder: (column) => column);

  GeneratedColumn<double> get x =>
      $composableBuilder(column: $table.x, builder: (column) => column);

  GeneratedColumn<double> get y =>
      $composableBuilder(column: $table.y, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);
}

class $$BoardTextsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BoardTextsTable,
          BoardText,
          $$BoardTextsTableFilterComposer,
          $$BoardTextsTableOrderingComposer,
          $$BoardTextsTableAnnotationComposer,
          $$BoardTextsTableCreateCompanionBuilder,
          $$BoardTextsTableUpdateCompanionBuilder,
          (
            BoardText,
            BaseReferences<_$AppDatabase, $BoardTextsTable, BoardText>,
          ),
          BoardText,
          PrefetchHooks Function()
        > {
  $$BoardTextsTableTableManager(_$AppDatabase db, $BoardTextsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BoardTextsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BoardTextsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BoardTextsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> viewId = const Value.absent(),
                Value<double?> x = const Value.absent(),
                Value<double?> y = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BoardTextsCompanion(
                id: id,
                viewId: viewId,
                x: x,
                y: y,
                content: content,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> viewId = const Value.absent(),
                Value<double?> x = const Value.absent(),
                Value<double?> y = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BoardTextsCompanion.insert(
                id: id,
                viewId: viewId,
                x: x,
                y: y,
                content: content,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BoardTextsTable, BoardText>(table),
                  BaseReferences<_$AppDatabase, $BoardTextsTable, BoardText>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BoardTextsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BoardTextsTable,
      BoardText,
      $$BoardTextsTableFilterComposer,
      $$BoardTextsTableOrderingComposer,
      $$BoardTextsTableAnnotationComposer,
      $$BoardTextsTableCreateCompanionBuilder,
      $$BoardTextsTableUpdateCompanionBuilder,
      (BoardText, BaseReferences<_$AppDatabase, $BoardTextsTable, BoardText>),
      BoardText,
      PrefetchHooks Function()
    >;
typedef $$BoardStrokesTableCreateCompanionBuilder =
    BoardStrokesCompanion Function({
      required String id,
      required String viewId,
      Value<String?> groupId,
      Value<int> zIndex,
      required String points,
      required String color,
      required double width,
      required String createdAt,
      Value<int> rowid,
    });
typedef $$BoardStrokesTableUpdateCompanionBuilder =
    BoardStrokesCompanion Function({
      Value<String> id,
      Value<String> viewId,
      Value<String?> groupId,
      Value<int> zIndex,
      Value<String> points,
      Value<String> color,
      Value<double> width,
      Value<String> createdAt,
      Value<int> rowid,
    });

class $$BoardStrokesTableFilterComposer
    extends Composer<_$AppDatabase, $BoardStrokesTable> {
  $$BoardStrokesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get viewId => $composableBuilder(
    column: $table.viewId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get zIndex => $composableBuilder(
    column: $table.zIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BoardStrokesTableOrderingComposer
    extends Composer<_$AppDatabase, $BoardStrokesTable> {
  $$BoardStrokesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get viewId => $composableBuilder(
    column: $table.viewId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get zIndex => $composableBuilder(
    column: $table.zIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BoardStrokesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BoardStrokesTable> {
  $$BoardStrokesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get viewId =>
      $composableBuilder(column: $table.viewId, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<int> get zIndex =>
      $composableBuilder(column: $table.zIndex, builder: (column) => column);

  GeneratedColumn<String> get points =>
      $composableBuilder(column: $table.points, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<double> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$BoardStrokesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BoardStrokesTable,
          BoardStroke,
          $$BoardStrokesTableFilterComposer,
          $$BoardStrokesTableOrderingComposer,
          $$BoardStrokesTableAnnotationComposer,
          $$BoardStrokesTableCreateCompanionBuilder,
          $$BoardStrokesTableUpdateCompanionBuilder,
          (
            BoardStroke,
            BaseReferences<_$AppDatabase, $BoardStrokesTable, BoardStroke>,
          ),
          BoardStroke,
          PrefetchHooks Function()
        > {
  $$BoardStrokesTableTableManager(_$AppDatabase db, $BoardStrokesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BoardStrokesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BoardStrokesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BoardStrokesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> viewId = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<int> zIndex = const Value.absent(),
                Value<String> points = const Value.absent(),
                Value<String> color = const Value.absent(),
                Value<double> width = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BoardStrokesCompanion(
                id: id,
                viewId: viewId,
                groupId: groupId,
                zIndex: zIndex,
                points: points,
                color: color,
                width: width,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String viewId,
                Value<String?> groupId = const Value.absent(),
                Value<int> zIndex = const Value.absent(),
                required String points,
                required String color,
                required double width,
                required String createdAt,
                Value<int> rowid = const Value.absent(),
              }) => BoardStrokesCompanion.insert(
                id: id,
                viewId: viewId,
                groupId: groupId,
                zIndex: zIndex,
                points: points,
                color: color,
                width: width,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BoardStrokesTable, BoardStroke>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $BoardStrokesTable,
                    BoardStroke
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BoardStrokesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BoardStrokesTable,
      BoardStroke,
      $$BoardStrokesTableFilterComposer,
      $$BoardStrokesTableOrderingComposer,
      $$BoardStrokesTableAnnotationComposer,
      $$BoardStrokesTableCreateCompanionBuilder,
      $$BoardStrokesTableUpdateCompanionBuilder,
      (
        BoardStroke,
        BaseReferences<_$AppDatabase, $BoardStrokesTable, BoardStroke>,
      ),
      BoardStroke,
      PrefetchHooks Function()
    >;
typedef $$BoardAlbumsTableCreateCompanionBuilder =
    BoardAlbumsCompanion Function({
      required String id,
      Value<String?> title,
      Value<String?> sourceViewId,
      required String strokesJson,
      Value<String?> thumbnailBase64,
      required String createdAt,
      Value<String?> updatedAt,
      Value<int> rowid,
    });
typedef $$BoardAlbumsTableUpdateCompanionBuilder =
    BoardAlbumsCompanion Function({
      Value<String> id,
      Value<String?> title,
      Value<String?> sourceViewId,
      Value<String> strokesJson,
      Value<String?> thumbnailBase64,
      Value<String> createdAt,
      Value<String?> updatedAt,
      Value<int> rowid,
    });

class $$BoardAlbumsTableFilterComposer
    extends Composer<_$AppDatabase, $BoardAlbumsTable> {
  $$BoardAlbumsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceViewId => $composableBuilder(
    column: $table.sourceViewId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get strokesJson => $composableBuilder(
    column: $table.strokesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailBase64 => $composableBuilder(
    column: $table.thumbnailBase64,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BoardAlbumsTableOrderingComposer
    extends Composer<_$AppDatabase, $BoardAlbumsTable> {
  $$BoardAlbumsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceViewId => $composableBuilder(
    column: $table.sourceViewId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get strokesJson => $composableBuilder(
    column: $table.strokesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailBase64 => $composableBuilder(
    column: $table.thumbnailBase64,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BoardAlbumsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BoardAlbumsTable> {
  $$BoardAlbumsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get sourceViewId => $composableBuilder(
    column: $table.sourceViewId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get strokesJson => $composableBuilder(
    column: $table.strokesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thumbnailBase64 => $composableBuilder(
    column: $table.thumbnailBase64,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BoardAlbumsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BoardAlbumsTable,
          BoardAlbum,
          $$BoardAlbumsTableFilterComposer,
          $$BoardAlbumsTableOrderingComposer,
          $$BoardAlbumsTableAnnotationComposer,
          $$BoardAlbumsTableCreateCompanionBuilder,
          $$BoardAlbumsTableUpdateCompanionBuilder,
          (
            BoardAlbum,
            BaseReferences<_$AppDatabase, $BoardAlbumsTable, BoardAlbum>,
          ),
          BoardAlbum,
          PrefetchHooks Function()
        > {
  $$BoardAlbumsTableTableManager(_$AppDatabase db, $BoardAlbumsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BoardAlbumsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BoardAlbumsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BoardAlbumsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> sourceViewId = const Value.absent(),
                Value<String> strokesJson = const Value.absent(),
                Value<String?> thumbnailBase64 = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BoardAlbumsCompanion(
                id: id,
                title: title,
                sourceViewId: sourceViewId,
                strokesJson: strokesJson,
                thumbnailBase64: thumbnailBase64,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> title = const Value.absent(),
                Value<String?> sourceViewId = const Value.absent(),
                required String strokesJson,
                Value<String?> thumbnailBase64 = const Value.absent(),
                required String createdAt,
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BoardAlbumsCompanion.insert(
                id: id,
                title: title,
                sourceViewId: sourceViewId,
                strokesJson: strokesJson,
                thumbnailBase64: thumbnailBase64,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BoardAlbumsTable, BoardAlbum>(table),
                  BaseReferences<_$AppDatabase, $BoardAlbumsTable, BoardAlbum>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BoardAlbumsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BoardAlbumsTable,
      BoardAlbum,
      $$BoardAlbumsTableFilterComposer,
      $$BoardAlbumsTableOrderingComposer,
      $$BoardAlbumsTableAnnotationComposer,
      $$BoardAlbumsTableCreateCompanionBuilder,
      $$BoardAlbumsTableUpdateCompanionBuilder,
      (
        BoardAlbum,
        BaseReferences<_$AppDatabase, $BoardAlbumsTable, BoardAlbum>,
      ),
      BoardAlbum,
      PrefetchHooks Function()
    >;
typedef $$NoteBookLinksTableCreateCompanionBuilder =
    NoteBookLinksCompanion Function({
      required String id,
      required String noteId,
      required String bookId,
      required String linkType,
      Value<String?> linkText,
      Value<String?> context,
      required String createdAt,
      Value<int> rowid,
    });
typedef $$NoteBookLinksTableUpdateCompanionBuilder =
    NoteBookLinksCompanion Function({
      Value<String> id,
      Value<String> noteId,
      Value<String> bookId,
      Value<String> linkType,
      Value<String?> linkText,
      Value<String?> context,
      Value<String> createdAt,
      Value<int> rowid,
    });

class $$NoteBookLinksTableFilterComposer
    extends Composer<_$AppDatabase, $NoteBookLinksTable> {
  $$NoteBookLinksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get noteId => $composableBuilder(
    column: $table.noteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linkType => $composableBuilder(
    column: $table.linkType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linkText => $composableBuilder(
    column: $table.linkText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get context => $composableBuilder(
    column: $table.context,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NoteBookLinksTableOrderingComposer
    extends Composer<_$AppDatabase, $NoteBookLinksTable> {
  $$NoteBookLinksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get noteId => $composableBuilder(
    column: $table.noteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkType => $composableBuilder(
    column: $table.linkType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkText => $composableBuilder(
    column: $table.linkText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get context => $composableBuilder(
    column: $table.context,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NoteBookLinksTableAnnotationComposer
    extends Composer<_$AppDatabase, $NoteBookLinksTable> {
  $$NoteBookLinksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get noteId =>
      $composableBuilder(column: $table.noteId, builder: (column) => column);

  GeneratedColumn<String> get bookId =>
      $composableBuilder(column: $table.bookId, builder: (column) => column);

  GeneratedColumn<String> get linkType =>
      $composableBuilder(column: $table.linkType, builder: (column) => column);

  GeneratedColumn<String> get linkText =>
      $composableBuilder(column: $table.linkText, builder: (column) => column);

  GeneratedColumn<String> get context =>
      $composableBuilder(column: $table.context, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$NoteBookLinksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NoteBookLinksTable,
          NoteBookLink,
          $$NoteBookLinksTableFilterComposer,
          $$NoteBookLinksTableOrderingComposer,
          $$NoteBookLinksTableAnnotationComposer,
          $$NoteBookLinksTableCreateCompanionBuilder,
          $$NoteBookLinksTableUpdateCompanionBuilder,
          (
            NoteBookLink,
            BaseReferences<_$AppDatabase, $NoteBookLinksTable, NoteBookLink>,
          ),
          NoteBookLink,
          PrefetchHooks Function()
        > {
  $$NoteBookLinksTableTableManager(_$AppDatabase db, $NoteBookLinksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NoteBookLinksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NoteBookLinksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NoteBookLinksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> noteId = const Value.absent(),
                Value<String> bookId = const Value.absent(),
                Value<String> linkType = const Value.absent(),
                Value<String?> linkText = const Value.absent(),
                Value<String?> context = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NoteBookLinksCompanion(
                id: id,
                noteId: noteId,
                bookId: bookId,
                linkType: linkType,
                linkText: linkText,
                context: context,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String noteId,
                required String bookId,
                required String linkType,
                Value<String?> linkText = const Value.absent(),
                Value<String?> context = const Value.absent(),
                required String createdAt,
                Value<int> rowid = const Value.absent(),
              }) => NoteBookLinksCompanion.insert(
                id: id,
                noteId: noteId,
                bookId: bookId,
                linkType: linkType,
                linkText: linkText,
                context: context,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NoteBookLinksTable, NoteBookLink>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $NoteBookLinksTable,
                    NoteBookLink
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NoteBookLinksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NoteBookLinksTable,
      NoteBookLink,
      $$NoteBookLinksTableFilterComposer,
      $$NoteBookLinksTableOrderingComposer,
      $$NoteBookLinksTableAnnotationComposer,
      $$NoteBookLinksTableCreateCompanionBuilder,
      $$NoteBookLinksTableUpdateCompanionBuilder,
      (
        NoteBookLink,
        BaseReferences<_$AppDatabase, $NoteBookLinksTable, NoteBookLink>,
      ),
      NoteBookLink,
      PrefetchHooks Function()
    >;
typedef $$NoteNoteLinksTableCreateCompanionBuilder =
    NoteNoteLinksCompanion Function({
      required String id,
      required String sourceNoteId,
      required String targetNoteId,
      required String linkType,
      Value<String?> linkText,
      required String createdAt,
      Value<int> rowid,
    });
typedef $$NoteNoteLinksTableUpdateCompanionBuilder =
    NoteNoteLinksCompanion Function({
      Value<String> id,
      Value<String> sourceNoteId,
      Value<String> targetNoteId,
      Value<String> linkType,
      Value<String?> linkText,
      Value<String> createdAt,
      Value<int> rowid,
    });

class $$NoteNoteLinksTableFilterComposer
    extends Composer<_$AppDatabase, $NoteNoteLinksTable> {
  $$NoteNoteLinksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceNoteId => $composableBuilder(
    column: $table.sourceNoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetNoteId => $composableBuilder(
    column: $table.targetNoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linkType => $composableBuilder(
    column: $table.linkType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linkText => $composableBuilder(
    column: $table.linkText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NoteNoteLinksTableOrderingComposer
    extends Composer<_$AppDatabase, $NoteNoteLinksTable> {
  $$NoteNoteLinksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceNoteId => $composableBuilder(
    column: $table.sourceNoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetNoteId => $composableBuilder(
    column: $table.targetNoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkType => $composableBuilder(
    column: $table.linkType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkText => $composableBuilder(
    column: $table.linkText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NoteNoteLinksTableAnnotationComposer
    extends Composer<_$AppDatabase, $NoteNoteLinksTable> {
  $$NoteNoteLinksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceNoteId => $composableBuilder(
    column: $table.sourceNoteId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetNoteId => $composableBuilder(
    column: $table.targetNoteId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get linkType =>
      $composableBuilder(column: $table.linkType, builder: (column) => column);

  GeneratedColumn<String> get linkText =>
      $composableBuilder(column: $table.linkText, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$NoteNoteLinksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NoteNoteLinksTable,
          NoteNoteLink,
          $$NoteNoteLinksTableFilterComposer,
          $$NoteNoteLinksTableOrderingComposer,
          $$NoteNoteLinksTableAnnotationComposer,
          $$NoteNoteLinksTableCreateCompanionBuilder,
          $$NoteNoteLinksTableUpdateCompanionBuilder,
          (
            NoteNoteLink,
            BaseReferences<_$AppDatabase, $NoteNoteLinksTable, NoteNoteLink>,
          ),
          NoteNoteLink,
          PrefetchHooks Function()
        > {
  $$NoteNoteLinksTableTableManager(_$AppDatabase db, $NoteNoteLinksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NoteNoteLinksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NoteNoteLinksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NoteNoteLinksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sourceNoteId = const Value.absent(),
                Value<String> targetNoteId = const Value.absent(),
                Value<String> linkType = const Value.absent(),
                Value<String?> linkText = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NoteNoteLinksCompanion(
                id: id,
                sourceNoteId: sourceNoteId,
                targetNoteId: targetNoteId,
                linkType: linkType,
                linkText: linkText,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sourceNoteId,
                required String targetNoteId,
                required String linkType,
                Value<String?> linkText = const Value.absent(),
                required String createdAt,
                Value<int> rowid = const Value.absent(),
              }) => NoteNoteLinksCompanion.insert(
                id: id,
                sourceNoteId: sourceNoteId,
                targetNoteId: targetNoteId,
                linkType: linkType,
                linkText: linkText,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NoteNoteLinksTable, NoteNoteLink>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $NoteNoteLinksTable,
                    NoteNoteLink
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NoteNoteLinksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NoteNoteLinksTable,
      NoteNoteLink,
      $$NoteNoteLinksTableFilterComposer,
      $$NoteNoteLinksTableOrderingComposer,
      $$NoteNoteLinksTableAnnotationComposer,
      $$NoteNoteLinksTableCreateCompanionBuilder,
      $$NoteNoteLinksTableUpdateCompanionBuilder,
      (
        NoteNoteLink,
        BaseReferences<_$AppDatabase, $NoteNoteLinksTable, NoteNoteLink>,
      ),
      NoteNoteLink,
      PrefetchHooks Function()
    >;
typedef $$SparksTableCreateCompanionBuilder =
    SparksCompanion Function({
      required String id,
      required String content,
      Value<String?> anchorNoteId,
      Value<String?> anchorLocation,
      Value<String> status,
      required String createdAt,
      Value<String?> updatedAt,
      Value<int> rowid,
    });
typedef $$SparksTableUpdateCompanionBuilder =
    SparksCompanion Function({
      Value<String> id,
      Value<String> content,
      Value<String?> anchorNoteId,
      Value<String?> anchorLocation,
      Value<String> status,
      Value<String> createdAt,
      Value<String?> updatedAt,
      Value<int> rowid,
    });

class $$SparksTableFilterComposer
    extends Composer<_$AppDatabase, $SparksTable> {
  $$SparksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get anchorNoteId => $composableBuilder(
    column: $table.anchorNoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get anchorLocation => $composableBuilder(
    column: $table.anchorLocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SparksTableOrderingComposer
    extends Composer<_$AppDatabase, $SparksTable> {
  $$SparksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get anchorNoteId => $composableBuilder(
    column: $table.anchorNoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get anchorLocation => $composableBuilder(
    column: $table.anchorLocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SparksTableAnnotationComposer
    extends Composer<_$AppDatabase, $SparksTable> {
  $$SparksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get anchorNoteId => $composableBuilder(
    column: $table.anchorNoteId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get anchorLocation => $composableBuilder(
    column: $table.anchorLocation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SparksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SparksTable,
          SparkRow,
          $$SparksTableFilterComposer,
          $$SparksTableOrderingComposer,
          $$SparksTableAnnotationComposer,
          $$SparksTableCreateCompanionBuilder,
          $$SparksTableUpdateCompanionBuilder,
          (SparkRow, BaseReferences<_$AppDatabase, $SparksTable, SparkRow>),
          SparkRow,
          PrefetchHooks Function()
        > {
  $$SparksTableTableManager(_$AppDatabase db, $SparksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SparksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SparksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SparksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> anchorNoteId = const Value.absent(),
                Value<String?> anchorLocation = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SparksCompanion(
                id: id,
                content: content,
                anchorNoteId: anchorNoteId,
                anchorLocation: anchorLocation,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String content,
                Value<String?> anchorNoteId = const Value.absent(),
                Value<String?> anchorLocation = const Value.absent(),
                Value<String> status = const Value.absent(),
                required String createdAt,
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SparksCompanion.insert(
                id: id,
                content: content,
                anchorNoteId: anchorNoteId,
                anchorLocation: anchorLocation,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SparksTable, SparkRow>(table),
                  BaseReferences<_$AppDatabase, $SparksTable, SparkRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SparksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SparksTable,
      SparkRow,
      $$SparksTableFilterComposer,
      $$SparksTableOrderingComposer,
      $$SparksTableAnnotationComposer,
      $$SparksTableCreateCompanionBuilder,
      $$SparksTableUpdateCompanionBuilder,
      (SparkRow, BaseReferences<_$AppDatabase, $SparksTable, SparkRow>),
      SparkRow,
      PrefetchHooks Function()
    >;
typedef $$NodeAnnotationsTableCreateCompanionBuilder =
    NodeAnnotationsCompanion Function({
      required String id,
      required String nodeId,
      required String strokesJson,
      required String createdAt,
      Value<String?> updatedAt,
      Value<int> rowid,
    });
typedef $$NodeAnnotationsTableUpdateCompanionBuilder =
    NodeAnnotationsCompanion Function({
      Value<String> id,
      Value<String> nodeId,
      Value<String> strokesJson,
      Value<String> createdAt,
      Value<String?> updatedAt,
      Value<int> rowid,
    });

class $$NodeAnnotationsTableFilterComposer
    extends Composer<_$AppDatabase, $NodeAnnotationsTable> {
  $$NodeAnnotationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get strokesJson => $composableBuilder(
    column: $table.strokesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NodeAnnotationsTableOrderingComposer
    extends Composer<_$AppDatabase, $NodeAnnotationsTable> {
  $$NodeAnnotationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get strokesJson => $composableBuilder(
    column: $table.strokesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NodeAnnotationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NodeAnnotationsTable> {
  $$NodeAnnotationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nodeId =>
      $composableBuilder(column: $table.nodeId, builder: (column) => column);

  GeneratedColumn<String> get strokesJson => $composableBuilder(
    column: $table.strokesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$NodeAnnotationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NodeAnnotationsTable,
          NodeAnnotation,
          $$NodeAnnotationsTableFilterComposer,
          $$NodeAnnotationsTableOrderingComposer,
          $$NodeAnnotationsTableAnnotationComposer,
          $$NodeAnnotationsTableCreateCompanionBuilder,
          $$NodeAnnotationsTableUpdateCompanionBuilder,
          (
            NodeAnnotation,
            BaseReferences<
              _$AppDatabase,
              $NodeAnnotationsTable,
              NodeAnnotation
            >,
          ),
          NodeAnnotation,
          PrefetchHooks Function()
        > {
  $$NodeAnnotationsTableTableManager(
    _$AppDatabase db,
    $NodeAnnotationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NodeAnnotationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NodeAnnotationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NodeAnnotationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nodeId = const Value.absent(),
                Value<String> strokesJson = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NodeAnnotationsCompanion(
                id: id,
                nodeId: nodeId,
                strokesJson: strokesJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nodeId,
                required String strokesJson,
                required String createdAt,
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NodeAnnotationsCompanion.insert(
                id: id,
                nodeId: nodeId,
                strokesJson: strokesJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NodeAnnotationsTable, NodeAnnotation>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $NodeAnnotationsTable,
                    NodeAnnotation
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NodeAnnotationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NodeAnnotationsTable,
      NodeAnnotation,
      $$NodeAnnotationsTableFilterComposer,
      $$NodeAnnotationsTableOrderingComposer,
      $$NodeAnnotationsTableAnnotationComposer,
      $$NodeAnnotationsTableCreateCompanionBuilder,
      $$NodeAnnotationsTableUpdateCompanionBuilder,
      (
        NodeAnnotation,
        BaseReferences<_$AppDatabase, $NodeAnnotationsTable, NodeAnnotation>,
      ),
      NodeAnnotation,
      PrefetchHooks Function()
    >;
typedef $$TagIndexTableCreateCompanionBuilder =
    TagIndexCompanion Function({
      required String id,
      Value<String> sourceType,
      required String sourceId,
      required String type,
      required String tag,
      Value<String?> blockId,
      Value<String?> textContent,
      required String createdAt,
      Value<int> rowid,
    });
typedef $$TagIndexTableUpdateCompanionBuilder =
    TagIndexCompanion Function({
      Value<String> id,
      Value<String> sourceType,
      Value<String> sourceId,
      Value<String> type,
      Value<String> tag,
      Value<String?> blockId,
      Value<String?> textContent,
      Value<String> createdAt,
      Value<int> rowid,
    });

class $$TagIndexTableFilterComposer
    extends Composer<_$AppDatabase, $TagIndexTable> {
  $$TagIndexTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get blockId => $composableBuilder(
    column: $table.blockId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textContent => $composableBuilder(
    column: $table.textContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TagIndexTableOrderingComposer
    extends Composer<_$AppDatabase, $TagIndexTable> {
  $$TagIndexTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get blockId => $composableBuilder(
    column: $table.blockId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textContent => $composableBuilder(
    column: $table.textContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagIndexTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagIndexTable> {
  $$TagIndexTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);

  GeneratedColumn<String> get blockId =>
      $composableBuilder(column: $table.blockId, builder: (column) => column);

  GeneratedColumn<String> get textContent => $composableBuilder(
    column: $table.textContent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TagIndexTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagIndexTable,
          TagIndexData,
          $$TagIndexTableFilterComposer,
          $$TagIndexTableOrderingComposer,
          $$TagIndexTableAnnotationComposer,
          $$TagIndexTableCreateCompanionBuilder,
          $$TagIndexTableUpdateCompanionBuilder,
          (
            TagIndexData,
            BaseReferences<_$AppDatabase, $TagIndexTable, TagIndexData>,
          ),
          TagIndexData,
          PrefetchHooks Function()
        > {
  $$TagIndexTableTableManager(_$AppDatabase db, $TagIndexTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagIndexTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagIndexTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagIndexTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> tag = const Value.absent(),
                Value<String?> blockId = const Value.absent(),
                Value<String?> textContent = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagIndexCompanion(
                id: id,
                sourceType: sourceType,
                sourceId: sourceId,
                type: type,
                tag: tag,
                blockId: blockId,
                textContent: textContent,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> sourceType = const Value.absent(),
                required String sourceId,
                required String type,
                required String tag,
                Value<String?> blockId = const Value.absent(),
                Value<String?> textContent = const Value.absent(),
                required String createdAt,
                Value<int> rowid = const Value.absent(),
              }) => TagIndexCompanion.insert(
                id: id,
                sourceType: sourceType,
                sourceId: sourceId,
                type: type,
                tag: tag,
                blockId: blockId,
                textContent: textContent,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TagIndexTable, TagIndexData>(table),
                  BaseReferences<_$AppDatabase, $TagIndexTable, TagIndexData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TagIndexTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagIndexTable,
      TagIndexData,
      $$TagIndexTableFilterComposer,
      $$TagIndexTableOrderingComposer,
      $$TagIndexTableAnnotationComposer,
      $$TagIndexTableCreateCompanionBuilder,
      $$TagIndexTableUpdateCompanionBuilder,
      (
        TagIndexData,
        BaseReferences<_$AppDatabase, $TagIndexTable, TagIndexData>,
      ),
      TagIndexData,
      PrefetchHooks Function()
    >;
typedef $$SearchIndexTableCreateCompanionBuilder =
    SearchIndexCompanion Function({
      required String id,
      required String sourceType,
      required String sourceId,
      Value<String?> subId,
      Value<String?> location,
      required String kind,
      required String searchText,
      Value<String?> rawText,
      required String createdAt,
      Value<int> rowid,
    });
typedef $$SearchIndexTableUpdateCompanionBuilder =
    SearchIndexCompanion Function({
      Value<String> id,
      Value<String> sourceType,
      Value<String> sourceId,
      Value<String?> subId,
      Value<String?> location,
      Value<String> kind,
      Value<String> searchText,
      Value<String?> rawText,
      Value<String> createdAt,
      Value<int> rowid,
    });

class $$SearchIndexTableFilterComposer
    extends Composer<_$AppDatabase, $SearchIndexTable> {
  $$SearchIndexTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subId => $composableBuilder(
    column: $table.subId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SearchIndexTableOrderingComposer
    extends Composer<_$AppDatabase, $SearchIndexTable> {
  $$SearchIndexTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subId => $composableBuilder(
    column: $table.subId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SearchIndexTableAnnotationComposer
    extends Composer<_$AppDatabase, $SearchIndexTable> {
  $$SearchIndexTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get subId =>
      $composableBuilder(column: $table.subId, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawText =>
      $composableBuilder(column: $table.rawText, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SearchIndexTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SearchIndexTable,
          SearchIndexData,
          $$SearchIndexTableFilterComposer,
          $$SearchIndexTableOrderingComposer,
          $$SearchIndexTableAnnotationComposer,
          $$SearchIndexTableCreateCompanionBuilder,
          $$SearchIndexTableUpdateCompanionBuilder,
          (
            SearchIndexData,
            BaseReferences<_$AppDatabase, $SearchIndexTable, SearchIndexData>,
          ),
          SearchIndexData,
          PrefetchHooks Function()
        > {
  $$SearchIndexTableTableManager(_$AppDatabase db, $SearchIndexTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SearchIndexTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SearchIndexTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SearchIndexTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<String?> subId = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> searchText = const Value.absent(),
                Value<String?> rawText = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SearchIndexCompanion(
                id: id,
                sourceType: sourceType,
                sourceId: sourceId,
                subId: subId,
                location: location,
                kind: kind,
                searchText: searchText,
                rawText: rawText,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sourceType,
                required String sourceId,
                Value<String?> subId = const Value.absent(),
                Value<String?> location = const Value.absent(),
                required String kind,
                required String searchText,
                Value<String?> rawText = const Value.absent(),
                required String createdAt,
                Value<int> rowid = const Value.absent(),
              }) => SearchIndexCompanion.insert(
                id: id,
                sourceType: sourceType,
                sourceId: sourceId,
                subId: subId,
                location: location,
                kind: kind,
                searchText: searchText,
                rawText: rawText,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SearchIndexTable, SearchIndexData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SearchIndexTable,
                    SearchIndexData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SearchIndexTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SearchIndexTable,
      SearchIndexData,
      $$SearchIndexTableFilterComposer,
      $$SearchIndexTableOrderingComposer,
      $$SearchIndexTableAnnotationComposer,
      $$SearchIndexTableCreateCompanionBuilder,
      $$SearchIndexTableUpdateCompanionBuilder,
      (
        SearchIndexData,
        BaseReferences<_$AppDatabase, $SearchIndexTable, SearchIndexData>,
      ),
      SearchIndexData,
      PrefetchHooks Function()
    >;
typedef $$WritingSessionsTableCreateCompanionBuilder =
    WritingSessionsCompanion Function({
      required String id,
      required String noteId,
      required String startAt,
      required String endAt,
      Value<int> wordCount,
      Value<int> pausedSeconds,
      Value<int> rowid,
    });
typedef $$WritingSessionsTableUpdateCompanionBuilder =
    WritingSessionsCompanion Function({
      Value<String> id,
      Value<String> noteId,
      Value<String> startAt,
      Value<String> endAt,
      Value<int> wordCount,
      Value<int> pausedSeconds,
      Value<int> rowid,
    });

class $$WritingSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $WritingSessionsTable> {
  $$WritingSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get noteId => $composableBuilder(
    column: $table.noteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endAt => $composableBuilder(
    column: $table.endAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wordCount => $composableBuilder(
    column: $table.wordCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pausedSeconds => $composableBuilder(
    column: $table.pausedSeconds,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WritingSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $WritingSessionsTable> {
  $$WritingSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get noteId => $composableBuilder(
    column: $table.noteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endAt => $composableBuilder(
    column: $table.endAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordCount => $composableBuilder(
    column: $table.wordCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pausedSeconds => $composableBuilder(
    column: $table.pausedSeconds,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WritingSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WritingSessionsTable> {
  $$WritingSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get noteId =>
      $composableBuilder(column: $table.noteId, builder: (column) => column);

  GeneratedColumn<String> get startAt =>
      $composableBuilder(column: $table.startAt, builder: (column) => column);

  GeneratedColumn<String> get endAt =>
      $composableBuilder(column: $table.endAt, builder: (column) => column);

  GeneratedColumn<int> get wordCount =>
      $composableBuilder(column: $table.wordCount, builder: (column) => column);

  GeneratedColumn<int> get pausedSeconds => $composableBuilder(
    column: $table.pausedSeconds,
    builder: (column) => column,
  );
}

class $$WritingSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WritingSessionsTable,
          WritingSessionRow,
          $$WritingSessionsTableFilterComposer,
          $$WritingSessionsTableOrderingComposer,
          $$WritingSessionsTableAnnotationComposer,
          $$WritingSessionsTableCreateCompanionBuilder,
          $$WritingSessionsTableUpdateCompanionBuilder,
          (
            WritingSessionRow,
            BaseReferences<
              _$AppDatabase,
              $WritingSessionsTable,
              WritingSessionRow
            >,
          ),
          WritingSessionRow,
          PrefetchHooks Function()
        > {
  $$WritingSessionsTableTableManager(
    _$AppDatabase db,
    $WritingSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WritingSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WritingSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WritingSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> noteId = const Value.absent(),
                Value<String> startAt = const Value.absent(),
                Value<String> endAt = const Value.absent(),
                Value<int> wordCount = const Value.absent(),
                Value<int> pausedSeconds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WritingSessionsCompanion(
                id: id,
                noteId: noteId,
                startAt: startAt,
                endAt: endAt,
                wordCount: wordCount,
                pausedSeconds: pausedSeconds,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String noteId,
                required String startAt,
                required String endAt,
                Value<int> wordCount = const Value.absent(),
                Value<int> pausedSeconds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WritingSessionsCompanion.insert(
                id: id,
                noteId: noteId,
                startAt: startAt,
                endAt: endAt,
                wordCount: wordCount,
                pausedSeconds: pausedSeconds,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WritingSessionsTable, WritingSessionRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $WritingSessionsTable,
                    WritingSessionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WritingSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WritingSessionsTable,
      WritingSessionRow,
      $$WritingSessionsTableFilterComposer,
      $$WritingSessionsTableOrderingComposer,
      $$WritingSessionsTableAnnotationComposer,
      $$WritingSessionsTableCreateCompanionBuilder,
      $$WritingSessionsTableUpdateCompanionBuilder,
      (
        WritingSessionRow,
        BaseReferences<_$AppDatabase, $WritingSessionsTable, WritingSessionRow>,
      ),
      WritingSessionRow,
      PrefetchHooks Function()
    >;
typedef $$FocusSessionsTableCreateCompanionBuilder =
    FocusSessionsCompanion Function({
      required String id,
      required String startAt,
      Value<int> minutes,
      Value<int> rowid,
    });
typedef $$FocusSessionsTableUpdateCompanionBuilder =
    FocusSessionsCompanion Function({
      Value<String> id,
      Value<String> startAt,
      Value<int> minutes,
      Value<int> rowid,
    });

class $$FocusSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $FocusSessionsTable> {
  $$FocusSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minutes => $composableBuilder(
    column: $table.minutes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FocusSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $FocusSessionsTable> {
  $$FocusSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minutes => $composableBuilder(
    column: $table.minutes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FocusSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FocusSessionsTable> {
  $$FocusSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get startAt =>
      $composableBuilder(column: $table.startAt, builder: (column) => column);

  GeneratedColumn<int> get minutes =>
      $composableBuilder(column: $table.minutes, builder: (column) => column);
}

class $$FocusSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FocusSessionsTable,
          FocusSessionRow,
          $$FocusSessionsTableFilterComposer,
          $$FocusSessionsTableOrderingComposer,
          $$FocusSessionsTableAnnotationComposer,
          $$FocusSessionsTableCreateCompanionBuilder,
          $$FocusSessionsTableUpdateCompanionBuilder,
          (
            FocusSessionRow,
            BaseReferences<_$AppDatabase, $FocusSessionsTable, FocusSessionRow>,
          ),
          FocusSessionRow,
          PrefetchHooks Function()
        > {
  $$FocusSessionsTableTableManager(_$AppDatabase db, $FocusSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FocusSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FocusSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FocusSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> startAt = const Value.absent(),
                Value<int> minutes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FocusSessionsCompanion(
                id: id,
                startAt: startAt,
                minutes: minutes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String startAt,
                Value<int> minutes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FocusSessionsCompanion.insert(
                id: id,
                startAt: startAt,
                minutes: minutes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FocusSessionsTable, FocusSessionRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $FocusSessionsTable,
                    FocusSessionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FocusSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FocusSessionsTable,
      FocusSessionRow,
      $$FocusSessionsTableFilterComposer,
      $$FocusSessionsTableOrderingComposer,
      $$FocusSessionsTableAnnotationComposer,
      $$FocusSessionsTableCreateCompanionBuilder,
      $$FocusSessionsTableUpdateCompanionBuilder,
      (
        FocusSessionRow,
        BaseReferences<_$AppDatabase, $FocusSessionsTable, FocusSessionRow>,
      ),
      FocusSessionRow,
      PrefetchHooks Function()
    >;
typedef $$ReadingStatsTableCreateCompanionBuilder =
    ReadingStatsCompanion Function({
      required String id,
      required String date,
      Value<int> minutes,
      Value<int> pages,
      required String createdAt,
      Value<int> rowid,
    });
typedef $$ReadingStatsTableUpdateCompanionBuilder =
    ReadingStatsCompanion Function({
      Value<String> id,
      Value<String> date,
      Value<int> minutes,
      Value<int> pages,
      Value<String> createdAt,
      Value<int> rowid,
    });

class $$ReadingStatsTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingStatsTable> {
  $$ReadingStatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minutes => $composableBuilder(
    column: $table.minutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pages => $composableBuilder(
    column: $table.pages,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadingStatsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingStatsTable> {
  $$ReadingStatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minutes => $composableBuilder(
    column: $table.minutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pages => $composableBuilder(
    column: $table.pages,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadingStatsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingStatsTable> {
  $$ReadingStatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get minutes =>
      $composableBuilder(column: $table.minutes, builder: (column) => column);

  GeneratedColumn<int> get pages =>
      $composableBuilder(column: $table.pages, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ReadingStatsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadingStatsTable,
          ReadingStat,
          $$ReadingStatsTableFilterComposer,
          $$ReadingStatsTableOrderingComposer,
          $$ReadingStatsTableAnnotationComposer,
          $$ReadingStatsTableCreateCompanionBuilder,
          $$ReadingStatsTableUpdateCompanionBuilder,
          (
            ReadingStat,
            BaseReferences<_$AppDatabase, $ReadingStatsTable, ReadingStat>,
          ),
          ReadingStat,
          PrefetchHooks Function()
        > {
  $$ReadingStatsTableTableManager(_$AppDatabase db, $ReadingStatsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingStatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingStatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingStatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<int> minutes = const Value.absent(),
                Value<int> pages = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingStatsCompanion(
                id: id,
                date: date,
                minutes: minutes,
                pages: pages,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String date,
                Value<int> minutes = const Value.absent(),
                Value<int> pages = const Value.absent(),
                required String createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ReadingStatsCompanion.insert(
                id: id,
                date: date,
                minutes: minutes,
                pages: pages,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReadingStatsTable, ReadingStat>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ReadingStatsTable,
                    ReadingStat
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadingStatsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadingStatsTable,
      ReadingStat,
      $$ReadingStatsTableFilterComposer,
      $$ReadingStatsTableOrderingComposer,
      $$ReadingStatsTableAnnotationComposer,
      $$ReadingStatsTableCreateCompanionBuilder,
      $$ReadingStatsTableUpdateCompanionBuilder,
      (
        ReadingStat,
        BaseReferences<_$AppDatabase, $ReadingStatsTable, ReadingStat>,
      ),
      ReadingStat,
      PrefetchHooks Function()
    >;
typedef $$CardsTableCreateCompanionBuilder =
    CardsCompanion Function({
      required String id,
      required String cardType,
      Value<String> sourceType,
      Value<String> sourceId,
      Value<String?> sourceTitle,
      Value<String> tags,
      Value<String> kind,
      Value<String> importance,
      Value<String?> front,
      Value<String?> back,
      Value<String?> indexTitle,
      Value<String?> author,
      Value<String?> highlight,
      Value<String?> anchor,
      Value<String?> question,
      Value<String?> answer,
      Value<String?> fillQuestion,
      Value<String?> fillAnswer,
      Value<String?> choiceQuestion,
      Value<String?> choiceOptions,
      Value<int?> choiceCorrectIndex,
      Value<String?> tfStatement,
      Value<bool?> tfIsTrue,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<String?> lastReviewDate,
      Value<String?> nextReviewDate,
      Value<double> memoryLevel,
      Value<String> relatedIds,
      Value<int> stage,
      Value<bool> mastered,
      Value<int> totalReviews,
      Value<int> failedCount,
      Value<int> usageCount,
      Value<int> rowid,
    });
typedef $$CardsTableUpdateCompanionBuilder =
    CardsCompanion Function({
      Value<String> id,
      Value<String> cardType,
      Value<String> sourceType,
      Value<String> sourceId,
      Value<String?> sourceTitle,
      Value<String> tags,
      Value<String> kind,
      Value<String> importance,
      Value<String?> front,
      Value<String?> back,
      Value<String?> indexTitle,
      Value<String?> author,
      Value<String?> highlight,
      Value<String?> anchor,
      Value<String?> question,
      Value<String?> answer,
      Value<String?> fillQuestion,
      Value<String?> fillAnswer,
      Value<String?> choiceQuestion,
      Value<String?> choiceOptions,
      Value<int?> choiceCorrectIndex,
      Value<String?> tfStatement,
      Value<bool?> tfIsTrue,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<String?> lastReviewDate,
      Value<String?> nextReviewDate,
      Value<double> memoryLevel,
      Value<String> relatedIds,
      Value<int> stage,
      Value<bool> mastered,
      Value<int> totalReviews,
      Value<int> failedCount,
      Value<int> usageCount,
      Value<int> rowid,
    });

class $$CardsTableFilterComposer extends Composer<_$AppDatabase, $CardsTable> {
  $$CardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cardType => $composableBuilder(
    column: $table.cardType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceTitle => $composableBuilder(
    column: $table.sourceTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get importance => $composableBuilder(
    column: $table.importance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get front => $composableBuilder(
    column: $table.front,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get back => $composableBuilder(
    column: $table.back,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get indexTitle => $composableBuilder(
    column: $table.indexTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get highlight => $composableBuilder(
    column: $table.highlight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get anchor => $composableBuilder(
    column: $table.anchor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get question => $composableBuilder(
    column: $table.question,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answer => $composableBuilder(
    column: $table.answer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fillQuestion => $composableBuilder(
    column: $table.fillQuestion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fillAnswer => $composableBuilder(
    column: $table.fillAnswer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get choiceQuestion => $composableBuilder(
    column: $table.choiceQuestion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get choiceOptions => $composableBuilder(
    column: $table.choiceOptions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get choiceCorrectIndex => $composableBuilder(
    column: $table.choiceCorrectIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tfStatement => $composableBuilder(
    column: $table.tfStatement,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get tfIsTrue => $composableBuilder(
    column: $table.tfIsTrue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastReviewDate => $composableBuilder(
    column: $table.lastReviewDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nextReviewDate => $composableBuilder(
    column: $table.nextReviewDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get memoryLevel => $composableBuilder(
    column: $table.memoryLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relatedIds => $composableBuilder(
    column: $table.relatedIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get mastered => $composableBuilder(
    column: $table.mastered,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalReviews => $composableBuilder(
    column: $table.totalReviews,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get failedCount => $composableBuilder(
    column: $table.failedCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get usageCount => $composableBuilder(
    column: $table.usageCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CardsTableOrderingComposer
    extends Composer<_$AppDatabase, $CardsTable> {
  $$CardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardType => $composableBuilder(
    column: $table.cardType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceTitle => $composableBuilder(
    column: $table.sourceTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get importance => $composableBuilder(
    column: $table.importance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get front => $composableBuilder(
    column: $table.front,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get back => $composableBuilder(
    column: $table.back,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get indexTitle => $composableBuilder(
    column: $table.indexTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get highlight => $composableBuilder(
    column: $table.highlight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get anchor => $composableBuilder(
    column: $table.anchor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get question => $composableBuilder(
    column: $table.question,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answer => $composableBuilder(
    column: $table.answer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fillQuestion => $composableBuilder(
    column: $table.fillQuestion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fillAnswer => $composableBuilder(
    column: $table.fillAnswer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get choiceQuestion => $composableBuilder(
    column: $table.choiceQuestion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get choiceOptions => $composableBuilder(
    column: $table.choiceOptions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get choiceCorrectIndex => $composableBuilder(
    column: $table.choiceCorrectIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tfStatement => $composableBuilder(
    column: $table.tfStatement,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get tfIsTrue => $composableBuilder(
    column: $table.tfIsTrue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastReviewDate => $composableBuilder(
    column: $table.lastReviewDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nextReviewDate => $composableBuilder(
    column: $table.nextReviewDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get memoryLevel => $composableBuilder(
    column: $table.memoryLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relatedIds => $composableBuilder(
    column: $table.relatedIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get mastered => $composableBuilder(
    column: $table.mastered,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalReviews => $composableBuilder(
    column: $table.totalReviews,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get failedCount => $composableBuilder(
    column: $table.failedCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get usageCount => $composableBuilder(
    column: $table.usageCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CardsTable> {
  $$CardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get cardType =>
      $composableBuilder(column: $table.cardType, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get sourceTitle => $composableBuilder(
    column: $table.sourceTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get importance => $composableBuilder(
    column: $table.importance,
    builder: (column) => column,
  );

  GeneratedColumn<String> get front =>
      $composableBuilder(column: $table.front, builder: (column) => column);

  GeneratedColumn<String> get back =>
      $composableBuilder(column: $table.back, builder: (column) => column);

  GeneratedColumn<String> get indexTitle => $composableBuilder(
    column: $table.indexTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get highlight =>
      $composableBuilder(column: $table.highlight, builder: (column) => column);

  GeneratedColumn<String> get anchor =>
      $composableBuilder(column: $table.anchor, builder: (column) => column);

  GeneratedColumn<String> get question =>
      $composableBuilder(column: $table.question, builder: (column) => column);

  GeneratedColumn<String> get answer =>
      $composableBuilder(column: $table.answer, builder: (column) => column);

  GeneratedColumn<String> get fillQuestion => $composableBuilder(
    column: $table.fillQuestion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fillAnswer => $composableBuilder(
    column: $table.fillAnswer,
    builder: (column) => column,
  );

  GeneratedColumn<String> get choiceQuestion => $composableBuilder(
    column: $table.choiceQuestion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get choiceOptions => $composableBuilder(
    column: $table.choiceOptions,
    builder: (column) => column,
  );

  GeneratedColumn<int> get choiceCorrectIndex => $composableBuilder(
    column: $table.choiceCorrectIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tfStatement => $composableBuilder(
    column: $table.tfStatement,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get tfIsTrue =>
      $composableBuilder(column: $table.tfIsTrue, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get lastReviewDate => $composableBuilder(
    column: $table.lastReviewDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nextReviewDate => $composableBuilder(
    column: $table.nextReviewDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get memoryLevel => $composableBuilder(
    column: $table.memoryLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relatedIds => $composableBuilder(
    column: $table.relatedIds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stage =>
      $composableBuilder(column: $table.stage, builder: (column) => column);

  GeneratedColumn<bool> get mastered =>
      $composableBuilder(column: $table.mastered, builder: (column) => column);

  GeneratedColumn<int> get totalReviews => $composableBuilder(
    column: $table.totalReviews,
    builder: (column) => column,
  );

  GeneratedColumn<int> get failedCount => $composableBuilder(
    column: $table.failedCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get usageCount => $composableBuilder(
    column: $table.usageCount,
    builder: (column) => column,
  );
}

class $$CardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CardsTable,
          CardsData,
          $$CardsTableFilterComposer,
          $$CardsTableOrderingComposer,
          $$CardsTableAnnotationComposer,
          $$CardsTableCreateCompanionBuilder,
          $$CardsTableUpdateCompanionBuilder,
          (CardsData, BaseReferences<_$AppDatabase, $CardsTable, CardsData>),
          CardsData,
          PrefetchHooks Function()
        > {
  $$CardsTableTableManager(_$AppDatabase db, $CardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> cardType = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<String?> sourceTitle = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> importance = const Value.absent(),
                Value<String?> front = const Value.absent(),
                Value<String?> back = const Value.absent(),
                Value<String?> indexTitle = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<String?> highlight = const Value.absent(),
                Value<String?> anchor = const Value.absent(),
                Value<String?> question = const Value.absent(),
                Value<String?> answer = const Value.absent(),
                Value<String?> fillQuestion = const Value.absent(),
                Value<String?> fillAnswer = const Value.absent(),
                Value<String?> choiceQuestion = const Value.absent(),
                Value<String?> choiceOptions = const Value.absent(),
                Value<int?> choiceCorrectIndex = const Value.absent(),
                Value<String?> tfStatement = const Value.absent(),
                Value<bool?> tfIsTrue = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String?> lastReviewDate = const Value.absent(),
                Value<String?> nextReviewDate = const Value.absent(),
                Value<double> memoryLevel = const Value.absent(),
                Value<String> relatedIds = const Value.absent(),
                Value<int> stage = const Value.absent(),
                Value<bool> mastered = const Value.absent(),
                Value<int> totalReviews = const Value.absent(),
                Value<int> failedCount = const Value.absent(),
                Value<int> usageCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CardsCompanion(
                id: id,
                cardType: cardType,
                sourceType: sourceType,
                sourceId: sourceId,
                sourceTitle: sourceTitle,
                tags: tags,
                kind: kind,
                importance: importance,
                front: front,
                back: back,
                indexTitle: indexTitle,
                author: author,
                highlight: highlight,
                anchor: anchor,
                question: question,
                answer: answer,
                fillQuestion: fillQuestion,
                fillAnswer: fillAnswer,
                choiceQuestion: choiceQuestion,
                choiceOptions: choiceOptions,
                choiceCorrectIndex: choiceCorrectIndex,
                tfStatement: tfStatement,
                tfIsTrue: tfIsTrue,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastReviewDate: lastReviewDate,
                nextReviewDate: nextReviewDate,
                memoryLevel: memoryLevel,
                relatedIds: relatedIds,
                stage: stage,
                mastered: mastered,
                totalReviews: totalReviews,
                failedCount: failedCount,
                usageCount: usageCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String cardType,
                Value<String> sourceType = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<String?> sourceTitle = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> importance = const Value.absent(),
                Value<String?> front = const Value.absent(),
                Value<String?> back = const Value.absent(),
                Value<String?> indexTitle = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<String?> highlight = const Value.absent(),
                Value<String?> anchor = const Value.absent(),
                Value<String?> question = const Value.absent(),
                Value<String?> answer = const Value.absent(),
                Value<String?> fillQuestion = const Value.absent(),
                Value<String?> fillAnswer = const Value.absent(),
                Value<String?> choiceQuestion = const Value.absent(),
                Value<String?> choiceOptions = const Value.absent(),
                Value<int?> choiceCorrectIndex = const Value.absent(),
                Value<String?> tfStatement = const Value.absent(),
                Value<bool?> tfIsTrue = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String?> lastReviewDate = const Value.absent(),
                Value<String?> nextReviewDate = const Value.absent(),
                Value<double> memoryLevel = const Value.absent(),
                Value<String> relatedIds = const Value.absent(),
                Value<int> stage = const Value.absent(),
                Value<bool> mastered = const Value.absent(),
                Value<int> totalReviews = const Value.absent(),
                Value<int> failedCount = const Value.absent(),
                Value<int> usageCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CardsCompanion.insert(
                id: id,
                cardType: cardType,
                sourceType: sourceType,
                sourceId: sourceId,
                sourceTitle: sourceTitle,
                tags: tags,
                kind: kind,
                importance: importance,
                front: front,
                back: back,
                indexTitle: indexTitle,
                author: author,
                highlight: highlight,
                anchor: anchor,
                question: question,
                answer: answer,
                fillQuestion: fillQuestion,
                fillAnswer: fillAnswer,
                choiceQuestion: choiceQuestion,
                choiceOptions: choiceOptions,
                choiceCorrectIndex: choiceCorrectIndex,
                tfStatement: tfStatement,
                tfIsTrue: tfIsTrue,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastReviewDate: lastReviewDate,
                nextReviewDate: nextReviewDate,
                memoryLevel: memoryLevel,
                relatedIds: relatedIds,
                stage: stage,
                mastered: mastered,
                totalReviews: totalReviews,
                failedCount: failedCount,
                usageCount: usageCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CardsTable, CardsData>(table),
                  BaseReferences<_$AppDatabase, $CardsTable, CardsData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CardsTable,
      CardsData,
      $$CardsTableFilterComposer,
      $$CardsTableOrderingComposer,
      $$CardsTableAnnotationComposer,
      $$CardsTableCreateCompanionBuilder,
      $$CardsTableUpdateCompanionBuilder,
      (CardsData, BaseReferences<_$AppDatabase, $CardsTable, CardsData>),
      CardsData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
  $$NodesTableTableManager get nodes =>
      $$NodesTableTableManager(_db, _db.nodes);
  $$BooksTableTableManager get books =>
      $$BooksTableTableManager(_db, _db.books);
  $$BookAnnotationsTableTableManager get bookAnnotations =>
      $$BookAnnotationsTableTableManager(_db, _db.bookAnnotations);
  $$BookHighlightsTableTableManager get bookHighlights =>
      $$BookHighlightsTableTableManager(_db, _db.bookHighlights);
  $$BookBookmarksTableTableManager get bookBookmarks =>
      $$BookBookmarksTableTableManager(_db, _db.bookBookmarks);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$PetsTableTableManager get pets => $$PetsTableTableManager(_db, _db.pets);
  $$UserSettingsTableTableTableManager get userSettingsTable =>
      $$UserSettingsTableTableTableManager(_db, _db.userSettingsTable);
  $$IsbnCacheTableTableManager get isbnCache =>
      $$IsbnCacheTableTableManager(_db, _db.isbnCache);
  $$PdfDrawingsTableTableManager get pdfDrawings =>
      $$PdfDrawingsTableTableManager(_db, _db.pdfDrawings);
  $$BoardViewsTableTableManager get boardViews =>
      $$BoardViewsTableTableManager(_db, _db.boardViews);
  $$BoardNodesTableTableManager get boardNodes =>
      $$BoardNodesTableTableManager(_db, _db.boardNodes);
  $$BoardEdgesTableTableManager get boardEdges =>
      $$BoardEdgesTableTableManager(_db, _db.boardEdges);
  $$BoardGroupsTableTableManager get boardGroups =>
      $$BoardGroupsTableTableManager(_db, _db.boardGroups);
  $$BoardTextsTableTableManager get boardTexts =>
      $$BoardTextsTableTableManager(_db, _db.boardTexts);
  $$BoardStrokesTableTableManager get boardStrokes =>
      $$BoardStrokesTableTableManager(_db, _db.boardStrokes);
  $$BoardAlbumsTableTableManager get boardAlbums =>
      $$BoardAlbumsTableTableManager(_db, _db.boardAlbums);
  $$NoteBookLinksTableTableManager get noteBookLinks =>
      $$NoteBookLinksTableTableManager(_db, _db.noteBookLinks);
  $$NoteNoteLinksTableTableManager get noteNoteLinks =>
      $$NoteNoteLinksTableTableManager(_db, _db.noteNoteLinks);
  $$SparksTableTableManager get sparks =>
      $$SparksTableTableManager(_db, _db.sparks);
  $$NodeAnnotationsTableTableManager get nodeAnnotations =>
      $$NodeAnnotationsTableTableManager(_db, _db.nodeAnnotations);
  $$TagIndexTableTableManager get tagIndex =>
      $$TagIndexTableTableManager(_db, _db.tagIndex);
  $$SearchIndexTableTableManager get searchIndex =>
      $$SearchIndexTableTableManager(_db, _db.searchIndex);
  $$WritingSessionsTableTableManager get writingSessions =>
      $$WritingSessionsTableTableManager(_db, _db.writingSessions);
  $$FocusSessionsTableTableManager get focusSessions =>
      $$FocusSessionsTableTableManager(_db, _db.focusSessions);
  $$ReadingStatsTableTableManager get readingStats =>
      $$ReadingStatsTableTableManager(_db, _db.readingStats);
  $$CardsTableTableManager get cards =>
      $$CardsTableTableManager(_db, _db.cards);
}
