// An object which can be embedded into a Quill document.
class EmbeddableM {
  const EmbeddableM(this.type, this.data);

  // The type of this object.
  final String type;

  // The data payload of this object.
  final dynamic data;

  Map<String, dynamic> toJson() {
    return {type: data};
  }

  static EmbeddableM fromJson(Map<String, dynamic> json) {
    final m = Map<String, dynamic>.from(json);

    assert(m.length == 1, 'Embeddable map must only have one key');

    return EmbeddableM(m.keys.first, m.values.first);
  }
}