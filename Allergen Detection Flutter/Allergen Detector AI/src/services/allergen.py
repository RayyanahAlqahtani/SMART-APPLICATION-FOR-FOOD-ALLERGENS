
import re
from fuzzywuzzy import fuzz

ALLERGEN_DATABASE = {
    "Peanut": [
        "peanut", "peanuts", "arachis hypogaea", "groundnut", "groundnuts",
        "monkey nut", "earth nut", "arachis oil", "peanut oil", "peanut butter",
        "peanut flour", "peanut protein",
    ],
    "Tree Nut": [
        "tree nut", "tree nuts", "almond", "almonds", "prunus dulcis",
        "cashew", "cashews", "anacardium occidentale",
        "walnut", "walnuts", "juglans regia",
        "pistachio", "pistachios", "pistacia vera",
        "pecan", "pecans", "carya illinoinensis",
        "macadamia", "macadamias", "macadamia ternifolia",
        "hazelnut", "hazelnuts", "filbert", "corylus avellana",
        "brazil nut", "brazil nuts", "bertholletia excelsa",
        "pine nut", "pine nuts", "pignoli",
        "chestnut", "chestnuts", "castanea",
        "praline", "marzipan", "nougat",
    ],
    "Milk": [
        "milk", "dairy", "lactose", "casein", "caseinate", "sodium caseinate",
        "calcium caseinate", "whey", "whey protein", "lactalbumin",
        "lactoglobulin", "ghee", "butter", "buttermilk", "cream",
        "cheese", "yogurt", "yoghurt", "curd", "curds",
        "skimmed milk", "whole milk", "milk powder", "milk solids",
        "condensed milk", "evaporated milk", "lactulose",
    ],
    "Egg": [
        "egg", "eggs", "egg white", "egg yolk", "albumin", "ovalbumin",
        "ovomucin", "ovomucoid", "ovovitellin", "ovotransferrin",
        "globulin", "lysozyme", "meringue", "mayonnaise",
        "lecithin", "egg lecithin", "egg protein",
    ],
    "Wheat": [
        "wheat", "wheat flour", "wheat starch", "wheat protein",
        "triticum", "triticum aestivum",
        "semolina", "durum", "spelt", "kamut", "einkorn", "emmer",
        "bulgur", "couscous", "farina", "seitan",
        "wheat germ", "wheat bran", "bread crumbs",
    ],
    "Gluten": [
        "gluten", "wheat gluten", "barley", "rye", "oat", "oats",
        "triticale", "malt", "malt extract", "malt flavoring",
        "brewer's yeast", "modified food starch",
        "hydrolyzed wheat protein", "hydrolyzed vegetable protein",
    ],
    "Soy": [
        "soy", "soya", "soybean", "soybeans", "soy protein",
        "soy lecithin", "soy sauce", "soy flour", "soy milk",
        "glycine max", "edamame", "tofu", "tempeh", "miso",
        "textured vegetable protein", "tvp",
        "soy protein isolate", "soy protein concentrate",
    ],
    "Fish": [
        "fish", "cod", "salmon", "tuna", "anchovy", "anchovies",
        "sardine", "sardines", "mackerel", "herring", "trout",
        "bass", "catfish", "tilapia", "haddock", "halibut",
        "pollock", "pike", "perch", "snapper",
        "fish oil", "fish gelatin", "fish sauce",
        "omega-3", "isinglass",
    ],
    "Shellfish": [
        "shellfish", "crustacean", "crustaceans",
        "shrimp", "prawn", "prawns", "crab", "lobster",
        "crayfish", "crawfish", "langoustine", "scampi", "krill",
        "mollusk", "mollusc", "clam", "clams", "mussel", "mussels",
        "oyster", "oysters", "scallop", "scallops",
        "squid", "calamari", "octopus", "snail", "abalone",
    ],
    "Sesame": [
        "sesame", "sesame seeds", "sesame oil", "tahini", "halva",
        "sesamum indicum", "sesame paste", "sesame flour",
    ],
    "Mustard": [
        "mustard", "mustard seed", "mustard oil", "mustard flour",
        "mustard powder", "sinapis", "brassica",
        "dijon", "yellow mustard", "brown mustard",
    ],
    "Celery": [
        "celery", "celeriac", "celery seed", "celery salt",
        "celery powder", "celery extract", "apium graveolens",
    ],
    "Lupin": [
        "lupin", "lupine", "lupini", "lupinus",
        "lupin flour", "lupin seed", "lupin protein",
    ],
    "Sulfite": [
        "sulfite", "sulphite", "sulfites", "sulphites",
        "sulfur dioxide", "sulphur dioxide", "so2",
        "sodium sulfite", "sodium bisulfite", "sodium metabisulfite",
        "potassium bisulfite", "potassium metabisulfite",
        "e220", "e221", "e222", "e223", "e224", "e225", "e226", "e227", "e228",
    ],
    "Corn": [
        "corn", "maize", "corn starch", "cornstarch", "corn flour",
        "corn syrup", "high fructose corn syrup", "hfcs",
        "corn oil", "corn meal", "cornmeal",
        "dextrose", "maltodextrin", "corn gluten",
    ],
}

_ALL_SYNONYMS = set()
for _syns in ALLERGEN_DATABASE.values():
    for _s in _syns:
        _ALL_SYNONYMS.add(_s.lower())


def analyze_ingredients(text, user_allergens=None):

    if not text or not text.strip():
        return {
            "is_safe": True,
            "risk_level": "Safe",
            "risk_score": 0,
            "found_allergens": [],
            "total_checked": 0,
            "highlighted_text": "",
        }

    text_lower = text.lower()

    if user_allergens:
        categories_to_check = {
            k: v for k, v in ALLERGEN_DATABASE.items()
            if k.lower() in [ua.lower() for ua in user_allergens]
        }
        for ua in user_allergens:
            if ua not in categories_to_check:
                categories_to_check[ua] = [ua.lower()]
    else:
        categories_to_check = ALLERGEN_DATABASE

    found = []
    matched_positions = []  

    for category, synonyms in categories_to_check.items():
        for term in synonyms:
            term_lower = term.lower()

            idx = text_lower.find(term_lower)
            if idx != -1:
                found.append({
                    "allergen": category,
                    "matched_term": term,
                    "method": "exact",
                    "confidence": 100,
                })
                matched_positions.append((idx, idx + len(term_lower), category))
                break  

            words_in_text = re.findall(r"[a-zA-Z]{3,}", text_lower)
            term_words = term_lower.split()

            if len(term_words) == 1 and len(term_lower) >= 4:
                for w in words_in_text:
                    ratio = fuzz.ratio(term_lower, w)
                    if ratio >= 85:
                        found.append({
                            "allergen": category,
                            "matched_term": f"{w} ≈ {term}",
                            "method": "fuzzy_word",
                            "confidence": ratio,
                        })
                        break
                else:
                    continue
                break

            if len(term_words) > 1:
                ratio = fuzz.partial_ratio(term_lower, text_lower)
                if ratio >= 88:
                    found.append({
                        "allergen": category,
                        "matched_term": term,
                        "method": "fuzzy_partial",
                        "confidence": ratio,
                    })
                    break

    seen_cats = set()
    unique_found = []
    for f in found:
        if f["allergen"] not in seen_cats:
            seen_cats.add(f["allergen"])
            unique_found.append(f)

    risk_score = _compute_risk_score(unique_found, len(categories_to_check))
    risk_level = _score_to_level(risk_score)

    highlighted_text = _highlight_allergens(text, matched_positions)

    return {
        "is_safe": len(unique_found) == 0,
        "risk_level": risk_level,
        "risk_score": round(risk_score, 1),
        "found_allergens": unique_found,
        "total_checked": len(categories_to_check),
        "highlighted_text": highlighted_text,
    }


def get_supported_allergens():
    return list(ALLERGEN_DATABASE.keys())

def _compute_risk_score(found_allergens, total_checked):
    if not found_allergens:
        return 0.0
    avg_conf = sum(f["confidence"] for f in found_allergens) / len(found_allergens)
    count_factor = min(len(found_allergens) / max(total_checked, 1), 1.0)
    return (avg_conf * 0.7) + (count_factor * 100 * 0.3)


def _score_to_level(score):
    if score == 0:
        return "Safe"
    if score < 40:
        return "Low"
    if score < 70:
        return "Medium"
    return "High"


def _highlight_allergens(text, positions):
    if not positions:
        return text
    positions_sorted = sorted(positions, key=lambda p: p[0], reverse=True)
    highlighted = text
    for start, end, _ in positions_sorted:
        highlighted = highlighted[:start] + "**" + highlighted[start:end] + "**" + highlighted[end:]
    return highlighted
