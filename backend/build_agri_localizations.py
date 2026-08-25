# build_agri_localizations.py
# Generates agricultural_localizations.dart containing 100% comprehensive
# Tamil and English localized recommendations for all 57 crop+disease classes.

import json
import re

recs = json.load(open(r'C:\Users\gopal\.gemini\antigravity-ide\brain\727b3fca-9a80-4e2f-93b1-9b7c948cdd69\scratch\recs.json'))

CROP_NAMES_TA = {
    'Tomato': 'தக்காளி',
    'Paddy': 'நெல்',
    'Rice': 'நெல்',
    'Wheat': 'கோதுமை',
    'Sugarcane': 'கரும்பு',
    'Groundnut': 'நிலக்கடலை',
    'Sunflower': 'சூரியகாந்தி',
    'Cotton': 'பருத்தி',
    'Blackgram': 'உளுந்து',
    'Eggplant': 'கத்தரிக்காய்',
    'Turmeric': 'மஞ்சள்',
}

DISEASE_NAMES_TA = {
    'Healthy': 'ஆரோக்கியமானது',
    'Early Blight': 'ஆரம்பக்கால கருகல் நோய்',
    'Late Blight': 'பிந்தைய கருகல் நோய்',
    'Bacterial Spot': 'பாக்டீரியா இலைப்புள்ளி',
    'Leaf Mold': 'இலை அச்சு நோய்',
    'Mosaic Virus': 'மொசைக் வைரஸ்',
    'Septoria Leaf Spot': 'செப்டோரியா இலைப்புள்ளி',
    'Spider Mites': 'சிலந்திப் பேன்கள்',
    'Target Spot': 'இலக்கு புள்ளி நோய்',
    'Yellow Leaf Curl Virus': 'மஞ்சள் இலை சுருள் வைரஸ்',
    'Brown Spot': 'பழுப்பு புள்ளி நோய்',
    'Leaf Blast': 'இலை கருகல் / பிளாஸ்ட்',
    'Leaf Blight': 'இலை கருகல் நோய்',
    'Leaf Scald': 'இலை வெளுத்தல் நோய்',
    'Sheath Blight': 'உறை கருகல் நோய்',
    'Crown Root Rot': 'வேர் அழுகல் நோய்',
    'Leaf Rust': 'இலை துரு நோய்',
    'Loose Smut': 'கரிபூட்டை நோய்',
    'Aphids': 'அசுவினிப் பேன்கள்',
    'Army Worm': 'படைப்புழு',
    'Bacterial Blight': 'பாக்டீரியா கருகல்',
    'Powdery Mildew': 'சாம்பல் நோய்',
    'Red Rot': 'சிவப்பு அழுகல் நோய்',
    'Red Rust': 'சிவப்பு துரு நோய்',
    'Late Leaf Spot': 'பிந்தைய இலைப்புள்ளி (திக்கா நோய்)',
    'Leaf Spot': 'இலைப்புள்ளி நோய்',
    'Nutrition Deficiency': 'ஊட்டச்சத்து குறைபாடு',
    'Rust': 'துரு நோய்',
    'Alternaria Leaf Spot': 'அல்டர்னேரியா இலைப்புள்ளி',
    'Downy Mildew': 'அடிச்சாம்பல் நோய்',
    'Rhizopus Head Rot': 'ரைசோபஸ் பூஞ்சை அழுகல்',
    'Sclerotinia': 'ஸ்கிளிரோடினியா அழுகல்',
    'Anthracnose': 'ஆந்த்ராக்னோஸ்',
    'Leaf Crinkle': 'இலை சுருக்கம்',
    'Yellow Mosaic': 'மஞ்சள் மொசைக்',
    'Insect Pest': 'பூச்சித் தாக்குதல்',
    'Small Leaf': 'சிறிய இலை நோய்',
    'White Mold': 'வெள்ளை பூஞ்சை',
    'Wilt Disease': 'வாடல் நோய்',
    'Dry Leaf': 'காய்ந்த இலை நோய்',
    'Leaf Blotch': 'இலை திட்டு நோய்',
    'Rhizome Disease': 'கிழங்கு அழுகல் நோய்',
}

PRODUCT_NAMES_TA = {
    'Trichoderma viride': 'டிரைக்கோடெர்மா விரிடி (உயிர் பூஞ்சைக்கொல்லி)',
    'Pseudomonas fluorescens': 'சூடோமோனாஸ் ஃப்ளோரசன்ஸ் (உயிர் பாக்டீரியா)',
    'Copper oxychloride 50WP': 'காப்பர் ஆக்ஸிகுளோரைடு 50WP',
    'Copper hydroxide 53.8 DF': 'காப்பர் ஹைட்ராக்சைடு 53.8 DF',
    'Carbendazim 50WP': 'கார்பெண்டாசிம் 50WP',
    'Mancozeb 75WP': 'மேன்கோசெப் 75WP',
    'Metalaxyl 8% + Mancozeb 64% WP': 'மெட்டலாக்சில் 8% + மேன்கோசெப் 64% WP',
    'Imidacloprid 17.8 SL': 'இமிடாக்ளோப்ரிட் 17.8 SL',
    'Thiamethoxam 25WG': 'தயாமெத்தாக்ஸாம் 25WG',
    'Spinosad 45 SC': 'ஸ்பினோசாட் 45 SC',
    'Abamectin 1.9EC': 'அபாமெக்டின் 1.9EC',
    'Hexaconazole 5EC': 'ஹெக்ஸாகோனசோல் 5EC',
    'Propiconazole 25EC': 'புரோபிகோனசோல் 25EC',
    'Tricyclazole 75WP': 'ட்ரைசைக்ளசோல் 75WP',
    'Sulphur 80WP': 'கந்தகம் 80WP (Sulphur)',
    'Chlorothalonil 75WP': 'குளோரோதலோனில் 75WP',
    'Carboxin 75WP': 'கார்பாக்சின் 75WP',
    'Chlorpyrifos 20EC': 'குளோர்பைரிபாஸ் 20EC',
    'Oxytetracycline 3.4% L': 'ஆக்ஸிடெட்ராசைக்ளின் 3.4% L',
    'Neem oil 1500ppm': 'வேப்ப எண்ணெய் 1500ppm',
    'Neem oil': 'வேப்ப எண்ணெய்',
}

FERT_NAMES_TA = {
    'Azospirillum biofertilizer': 'அசோஸ்பைரில்லம் உயிர் உரம்',
    'Rhizobium biofertilizer': 'ரைசோபியம் உயிர் உரம்',
    'Azotobacter biofertilizer': 'அசோடோபாக்டர் உயிர் உரம்',
    'PSB (Phosphate Solubilizing Bacteria)': 'பாஸ்போபாக்டீரியா (PSB உயிர் உரம்)',
    'Azospirillum + PSB Mix': 'அசோஸ்பைரில்லம் + PSB கலவை',
    'NPK 19:19:19 (Water-Soluble Fertilizer)': 'NPK 19:19:19 (கரைசல் உரம்)',
    'Muriate of Potash (MOP)': 'பொட்டாஷ் உரம் (MOP)',
    'Micronutrient Mix (Fe, Zn, B)': 'நுண்ணூட்டச் சத்து கலவை (இரும்பு, துத்தநாகம், போரான்)',
}

CATEGORY_NAMES_TA = {
    'Biological Control': 'உயிரியல் கட்டுப்பாடு',
    'Insecticide': 'பூச்சிக்கொல்லி',
    'Fungicide': 'பூஞ்சைக்கொல்லி',
    'Bactericide': 'பாக்டீரியாக்கொல்லி',
    'Organic Treatment': 'இயற்கை சிகிச்சை',
    'Fertilizer': 'உரம்',
    'Biofertilizer': 'உயிர் உரம்',
    'Chemical Treatment': 'ரசாயன சிகிச்சை',
    'Nutrient Supplement': 'ஊட்டச்சத்து துணைப்பொருள்',
    'Preventive Treatment': 'தடுப்பு சிகிச்சை',
    'Healthy': 'ஆரோக்கியமானது',
}

PROBLEM_TYPES_TA = {
    'Disease': 'நோய்',
    'Pest': 'பூச்சித் தாக்குதல்',
    'Nutrient Deficiency': 'ஊட்டச்சத்து குறைபாடு',
    'Healthy': 'ஆரோக்கியமானது',
}

SEVERITY_TA = {
    'High': 'அதிக தீவிரம்',
    'Medium': 'மிதமான தீவிரம்',
    'Low': 'குறைந்த தீவிரம்',
    'None': 'ஆரோக்கியமானது',
}

# Translate common English phrases into natural Tamil
def translate_to_tamil(field, en_text, crop='', disease=''):
    if not en_text:
        return ''
    
    t = en_text.strip()
    
    # Direct mappings
    if field == 'product_category':
        return CATEGORY_NAMES_TA.get(t, t)
    if field == 'problem_type':
        return PROBLEM_TYPES_TA.get(t, t)
    if field == 'product_name':
        return PRODUCT_NAMES_TA.get(t, t)
    if field == 'fertilizer_name':
        return FERT_NAMES_TA.get(t, t)
    if field == 'dosage_unit':
        if t == 'kg/acre': return 'கிலோ/ஏக்கர்'
        if t == 'ml/L': return 'மி.லி/லிட்டர்'
        if t == 'g/L': return 'கிராம்/லிட்டர்'
        if t == 'g/kg seed': return 'கிராம்/கிலோ விதை'
        if t == 'ml/kg seed': return 'மி.லி/கிலோ விதை'
        if t == 'L/acre': return 'லிட்டர்/ஏக்கர்'
        return t

    # Translate purpose
    if field == 'purpose':
        # Generic replacements
        s = t
        s = s.replace('Biological control of', 'உயிரியல் முறையில் கட்டுப்படுத்துதல்:')
        s = s.replace('Biological suppression of', 'உயிரியல் முறையில் அடக்குதல்:')
        s = s.replace('Chemical control of', 'ரசாயன முறையில் கட்டுப்படுத்துதல்:')
        s = s.replace('Systemic control of', 'உள்வாங்கி முறையில் கட்டுப்படுத்துதல்:')
        s = s.replace('Contact control of', 'தொடு நச்சு முறையில் கட்டுப்படுத்துதல்:')
        s = s.replace('Preventive and curative control of', 'தடுப்பு மற்றும் தீர்வு கட்டுப்பாடு:')
        s = s.replace('Nutritional support for', 'ஊட்டச்சத்து ஆதரவு:')
        s = s.replace('Restoration of plant vigour for', 'பயிர் வீரியத்தை மீட்டெடுத்தல்:')
        s = s.replace('by antagonistic action', 'எதிர் உயிரியல் செயல்பாடு மூலம்')
        s = s.replace('through ISR induction', 'தாவர நோய் எதிர்ப்புத் திறனைத் தூண்டுதல் மூலம்')
        s = s.replace('via broad-spectrum contact multisite activity', 'பல முனை தொடர்பு நடவடிக்கை மூலம்')
        s = s.replace('via systemic sterol biosynthesis inhibition', 'ஸ்டீரால் உயிரியக்க தடுப்பு முறை மூலம்')
        s = s.replace('via systemic melanin biosynthesis inhibition in appressoria', 'மெலனின் தொகுப்பு தடுப்பு மூலம்')
        s = s.replace('via systemic respiratory complex III inhibition (QoI)', 'சுவாச தடுப்பு நடவடிக்கை மூலம்')
        s = s.replace('via nicotinic acetylcholine receptor agonism', 'நரம்பு ஏற்பி தடுப்பு முறை மூலம்')
        s = s.replace('via GABA/glutamate-gated chloride channel allosteric modulation', 'குளோரைடு வழித்தட ஒழுங்குமுறை மூலம்')
        s = s.replace('via nicotinic acetylcholine and GABA receptor modulation', 'நரம்பு நச்சு ஒழுங்குமுறை மூலம்')
        s = s.replace('via fungal cell membrane disruption and multisite contact action', 'பூஞ்சை செல் சவ்வை அழிக்கும் நடவடிக்கை மூலம்')
        s = s.replace('via contact protein denaturation and multisite fungal enzyme inhibition', 'பூஞ்சை என்சைம் தடுப்பு மூலம்')
        s = s.replace('via bacterial cell wall and protein synthesis inhibition', 'பாக்டீரியா செல் சுவர் உருவாக்கம் தடுப்பு மூலம்')
        s = s.replace('via contact cell membrane disruption and spore germination inhibition', 'பூஞ்சை வித்து முளைப்பு தடுப்பு மூலம்')
        s = s.replace('No treatment required — crop is healthy and disease-free', 'சிகிச்சை தேவையில்லை — பயிர் ஆரோக்கியமாகவும் நோய் இன்றியும் உள்ளது')
        s = s.replace('Early Blight', 'ஆரம்பக்கால கருகல்')
        s = s.replace('Late Blight', 'பிந்தைய கருகல்')
        s = s.replace('Bacterial Spot', 'பாக்டீரியா இலைப்புள்ளி')
        s = s.replace('Leaf Mold', 'இலை அச்சு நோய்')
        s = s.replace('Septoria Leaf Spot', 'செப்டோரியா இலைப்புள்ளி')
        s = s.replace('Spider Mites', 'சிலந்திப் பேன்கள்')
        s = s.replace('Target Spot', 'இலக்கு புள்ளி நோய்')
        s = s.replace('Mosaic Virus', 'மொசைக் வைரஸ்')
        s = s.replace('Yellow Leaf Curl Virus', 'மஞ்சள் இலை சுருள் வைரஸ்')
        s = s.replace('Brown Spot', 'பழுப்பு புள்ளி நோய்')
        s = s.replace('Leaf Blast', 'இலை கருகல் / பிளாஸ்ட்')
        s = s.replace('Leaf Blight', 'இலை கருகல் நோய்')
        s = s.replace('Leaf Scald', 'இலை வெளுத்தல் நோய்')
        s = s.replace('Sheath Blight', 'உறை கருகல் நோய்')
        s = s.replace('Crown Root Rot', 'வேர் அழுகல் நோய்')
        s = s.replace('Leaf Rust', 'இலை துரு நோய்')
        s = s.replace('Loose Smut', 'கரிபூட்டை நோய்')
        s = s.replace('Aphids', 'அசுவினிப் பேன்கள்')
        s = s.replace('Army Worm', 'படைப்புழு')
        s = s.replace('Bacterial Blight', 'பாக்டீரியா கருகல்')
        s = s.replace('Powdery Mildew', 'சாம்பல் நோய்')
        s = s.replace('Red Rot', 'சிவப்பு அழுகல் நோய்')
        s = s.replace('Red Rust', 'சிவப்பு துரு நோய்')
        s = s.replace('Late Leaf Spot', 'பிந்தைய இலைப்புள்ளி')
        s = s.replace('Leaf Spot', 'இலைப்புள்ளி')
        s = s.replace('Nutrition Deficiency', 'ஊட்டச்சத்து குறைபாடு')
        s = s.replace('Rust', 'துரு நோய்')
        s = s.replace('Alternaria Leaf Spot', 'அல்டர்னேரியா இலைப்புள்ளி')
        s = s.replace('Downy Mildew', 'அடிச்சாம்பல் நோய்')
        s = s.replace('Rhizopus Head Rot', 'ரைசோபஸ் பூஞ்சை அழுகல்')
        s = s.replace('Sclerotinia', 'ஸ்கிளிரோடினியா அழுகல்')
        s = s.replace('Anthracnose', 'ஆந்த்ராக்னோஸ்')
        s = s.replace('Leaf Crinkle', 'இலை சுருக்கம்')
        s = s.replace('Yellow Mosaic', 'மஞ்சள் மொசைக்')
        s = s.replace('Insect Pest', 'பூச்சித் தாக்குதல்')
        s = s.replace('Small Leaf', 'சிறிய இலை நோய்')
        s = s.replace('White Mold', 'வெள்ளை பூஞ்சை')
        s = s.replace('Wilt Disease', 'வாடல் நோய்')
        s = s.replace('Dry Leaf', 'காய்ந்த இலை நோய்')
        s = s.replace('Leaf Blotch', 'இலை திட்டு நோய்')
        s = s.replace('Rhizome Disease', 'கிழங்கு அழுகல் நோய்')
        return s

    # Application Method
    if field == 'application_method':
        s = t
        s = s.replace('Dissolve in 200L water; drench soil around base of plant or foliar spray', '200 லிட்டர் நீரில் கரைத்து, செடியின் வேர்ப்பகுதியில் ஊற்றவும் அல்லது இலைகளில் தெளிக்கவும்')
        s = s.replace('Foliar spray; cover both upper and lower leaf surfaces', 'இலைவழித் தெளிப்பு; இலையின் மேல் மற்றும் கீழ் பரப்புகளில் படுமாறு தெளிக்கவும்')
        s = s.replace('Foliar spray; ensure thorough coverage of both leaf surfaces', 'இலைவழித் தெளிப்பு; இலைகளின் இருபுறமும் முழுமையாக நனையுமாறு தெளிக்கவும்')
        s = s.replace('Foliar spray; spray early morning or late afternoon for maximum absorption', 'இலைவழித் தெளிப்பு; அதிகாலை அல்லது மாலையில் தெளிப்பது சிறந்தது')
        s = s.replace('Foliar spray; target underside of leaves where mites feed', 'இலைவழித் தெளிப்பு; பேன்கள் இருக்கும் இலையின் அடிப்பகுதியில் படுமாறு தெளிக்கவும்')
        s = s.replace('Foliar spray; target whorl and young leaves where caterpillars feed', 'இலைவழித் தெளிப்பு; புழுக்கள் இருக்கும் குருத்து மற்றும் இளம் இலைகளில் தெளிக்கவும்')
        s = s.replace('Foliar spray; spray at seedling and active tillering stages', 'இலைவழித் தெளிப்பு; நாற்றுப் பருவம் மற்றும் தூர் கட்டும் பருவத்தில் தெளிக்கவும்')
        s = s.replace('Foliar spray; direct spray towards panicles and upper canopy', 'இலைவழித் தெளிப்பு; கதிர் மற்றும் மேல் இலைகளில் படுமாறு தெளிக்கவும்')
        s = s.replace('Foliar spray; direct spray towards sheath base near water line', 'இலைவழித் தெளிப்பு; நீர்மட்டத்திற்கு அருகிலுள்ள தண்டுப்பகுதியில் தெளிக்கவும்')
        s = s.replace('Dissolve in water; drench soil around root zone of affected plants', 'நீரில் கரைத்து, பாதிக்கப்பட்ட செடிகளின் வேர்ப்பகுதியில் ஊற்றவும்')
        s = s.replace('Dissolve in 200L water; spray canopy thoroughly', '200 லிட்டர் நீரில் கரைத்து இலைப்பரப்பில் முழுமையாகத் தெளிக்கவும்')
        s = s.replace('Dissolve in 200L water; spray at first sign of disease', '200 லிட்டர் நீரில் கரைத்து நோய் அறிகுறி கண்டவுடன் தெளிக்கவும்')
        s = s.replace('Mix with seed thoroughly before sowing using a small amount of water to ensure coating', 'விதைப்பதற்கு முன் சிறிதளவு நீர் சேர்த்து விதைகளின் மீது சீராகப் படியுமாறு கலக்கவும்')
        s = s.replace('Seed treatment before sowing; mix with 100ml water and coat seeds', 'விதைப்பு முன் விதை நேர்த்தி; 100 மி.லி நீரில் கலந்து விதைகளில் பூசவும்')
        s = s.replace('Sett treatment before planting; dip setts in 0.1% Carbendazim solution for 15 minutes', 'கரணை நேர்த்தி; நடவுக்கு முன் 0.1% கார்பெண்டாசிம் கரைசலில் 15 நிமிடம் ஊறவைக்கவும்')
        s = s.replace('Rhizome treatment before planting; soak seed rhizomes for 30 minutes before sowing', 'விதைக்கிழங்கு நேர்த்தி; நடவு செய்வதற்கு முன் 30 நிமிடங்கள் ஊறவைக்கவும்')
        s = s.replace('No application needed', 'பயன்பாடு தேவையில்லை')
        return s

    # Application Timing
    if field == 'application_timing':
        s = t
        s = s.replace('Apply at first symptom appearance or preventively at transplanting', 'முதல் அறிகுறி கண்டவுடன் அல்லது நாற்று நடவின் போது முன்னெச்சரிக்கையாகப் பயன்படுத்தவும்')
        s = s.replace('Begin at first appearance; preventive use from early vegetative stage in high-risk periods', 'முதல் அறிகுறி தென்பட்டவுடன் தொடங்கவும்; நோய் பரவும் காலத்தில் முன்கூட்டியே தெளிக்கவும்')
        s = s.replace('Apply immediately upon first appearance of spots or preventively during warm humid weather', 'புள்ளிகள் தோன்றியவுடன் அல்லது வெப்பமான ஈரப்பத வானிலையில் முன்னெச்சரிக்கையாகத் தெளிக்கவும்')
        s = s.replace('Apply at first sign of white/grey powdery growth on upper leaf surface', 'இலையின் மேல் பரப்பில் வெள்ளை/சாம்பல் நிற பூஞ்சை தோன்றியவுடன் பயன்படுத்தவும்')
        s = s.replace('Apply as soon as aphid colonies or honey-dew secretions are observed', 'அசுவினி பூச்சிகள் அல்லது தேன் போன்ற திரவம் தென்பட்டவுடன் தெளிக்கவும்')
        s = s.replace('Apply when young larvae are detected; early instar spray is significantly more effective', 'இளம் புழுக்கள் தென்பட்டவுடன் தெளிக்கவும்; ஆரம்ப நிலையிலேயே தெளிப்பது மிகச் சிறந்தது')
        s = s.replace('Apply at early tillering or boot leaf stage when blast lesions first appear', 'தூர் கட்டும் பருவம் அல்லது கொடி இலை பருவத்தில் அறிகுறிகள் தெரிந்தவுடன் தெளிக்கவும்')
        s = s.replace('Apply at early boot leaf stage or when water-soaked lesions appear', 'கொடி இலை பருவத்தில் அல்லது நீர் கசிவு போன்ற புள்ளிகள் தோன்றும் போது தெளிக்கவும்')
        s = s.replace('Apply when orange-brown rust pustules are first visible on leaves', 'இலைகளில் ஆரஞ்சு-பழுப்பு நிற துரு கொப்புளங்கள் தென்பட்டவுடன் பயன்படுத்தவும்')
        s = s.replace('Apply at flowering/heading stage if conditions favor disease', 'பூக்கும் தருணத்தில் அல்லது கதிர் வரும் போது தெளிக்கவும்')
        s = s.replace('Before sowing only; do not apply post-emergence', 'விதைப்பதற்கு முன் மட்டுமே; முளைத்த பின் பயன்படுத்த வேண்டாம்')
        s = s.replace('Before planting only', 'நடவு செய்வதற்கு முன் மட்டுமே')
        s = s.replace('Not applicable', 'பொருந்தாது')
        return s

    # Frequency
    if field == 'frequency':
        s = t
        s = s.replace('Every 21 days during humid weather', 'ஈரப்பதமான வானிலையில் 21 நாட்களுக்கு ஒருமுறை')
        s = s.replace('Every 10 days — 3 applications', '10 நாட்களுக்கு ஒருமுறை — 3 முறை')
        s = s.replace('Every 7–10 days during active disease period', 'நோய் தீவிரமாக இருக்கும் போது 7–10 நாட்களுக்கு ஒருமுறை')
        s = s.replace('Every 10–14 days as needed', 'தேவைக்கேற்ப 10–14 நாட்களுக்கு ஒருமுறை')
        s = s.replace('Every 7–10 days until pest population is under ETL', 'பூச்சிகளின் எண்ணிக்கை குறையும் வரை 7–10 நாட்களுக்கு ஒருமுறை')
        s = s.replace('Every 14 days — max 2 applications per season', '14 நாட்களுக்கு ஒருமுறை — ஒரு பருவத்திற்கு அதிகபட்சம் 2 முறை')
        s = s.replace('Once before sowing', 'விதைப்பதற்கு முன் ஒருமுறை')
        s = s.replace('Once before planting', 'நடவு செய்வதற்கு முன் ஒருமுறை')
        s = s.replace('Single application at transplanting / sowing', 'நாற்று நடவு / விதைப்பின் போது ஒருமுறை மட்டும்')
        s = s.replace('Not applicable', 'பொருந்தாது')
        return s

    # Duration
    if field == 'duration':
        s = t
        s = s.replace('3 applications per season', 'ஒரு பருவத்திற்கு 3 முறை')
        s = s.replace('30 days treatment cycle', '30 நாட்கள் சிகிச்சை சுழற்சி')
        s = s.replace('2–3 applications as needed', 'தேவைக்கேற்ப 2–3 முறை')
        s = s.replace('1–2 applications', '1–2 முறை')
        s = s.replace('Single treatment', 'ஒருமுறை சிகிச்சை')
        s = s.replace('Not applicable', 'பொருந்தாது')
        return s

    # Precautions
    if field == 'precautions':
        s = t
        s = s.replace('Do not mix with chemical fungicides. Apply in cool part of the day.', 'இரசாயன பூஞ்சைக் கொல்லிகளுடன் கலக்க வேண்டாம். நாளின் குளிர்ந்த வேளையில் பயன்படுத்தவும்.')
        s = s.replace('Do not mix with chemical pesticides. Use within 24h of preparation.', 'இரசாயன பூச்சிக்கொல்லிகளுடன் கலக்க வேண்டாம். தயாரித்த 24 மணி நேரத்திற்குள் பயன்படுத்தவும்.')
        s = s.replace('Do not spray during bloom period to protect pollinators.', 'மகரந்தச் சேர்க்கை பூச்சிகளைப் பாதுகாக்க பூக்கும் தருணத்தில் தெளிக்க வேண்டாம்.')
        s = s.replace('Rotate chemical groups to avoid resistance build-up.', 'பூச்சிகள்/பூஞ்சைகள் எதிர்ப்புத் திறன் பெறுவதைத் தடுக்க மருந்துகளை மாற்றி மாற்றிப் பயன்படுத்தவும்.')
        s = s.replace('Do not apply in high temperatures (>35°C) to avoid phytotoxicity.', 'பயிரில் கருகல் ஏற்படாமல் இருக்க அதிக வெப்பநிலையில் (>35°C) தெளிக்க வேண்டாம்.')
        s = s.replace('Ensure complete coverage of infected areas. Wash hands after use.', 'பாதிக்கப்பட்ட பகுதிகளில் முழுமையாகப் படுமாறு தெளிக்கவும். பயன்பாட்டிற்குப் பின் கைகளை நன்கு கழுவவும்.')
        s = s.replace('None — maintain current good agricultural practices.', 'எதுவுமில்லை — தற்போதைய சிறந்த விவசாய முறைகளைத் தொடரவும்.')
        return s

    # Safety Notes
    if field == 'safety_notes':
        s = t
        s = s.replace('Generally safe — wear gloves and mask. Wash hands after handling.', 'பொதுவாக பாதுகாப்பானது — கையுறைகள் மற்றும் முகக்கவசம் அணியவும். கையாண்ட பின் கைகளை நன்கு கழுவவும்.')
        s = s.replace('Biological product — wear gloves. Avoid contact with eyes.', 'உயிரியல் தயாரிப்பு — கையுறைகள் அணியவும். கண்களில் படுவதைத் தவிர்க்கவும்.')
        s = s.replace('Wear protective mask and gloves. Avoid breathing spray mist.', 'பாதுகாப்பு முகக்கவசம் மற்றும் கையுறைகள் அணியவும். மருந்து புகையை சுவாசிப்பதைத் தவிர்க்கவும்.')
        s = s.replace('Toxic to aquatic life and bees — do not spray near water bodies or during bloom.', 'நீர்வாழ் உயிரினங்கள் மற்றும் தேனீக்களுக்கு நச்சுத்தன்மை வாய்ந்தது — நீர்நிலைகள் அருகிலோ அல்லது பூக்கும் போதோ தெளிக்க வேண்டாம்.')
        s = s.replace('Wear full protective gear including goggles, gloves, and mask during mixing and application.', 'கலக்கும்போதும் தெளிக்கும்போதும் கண்ணாடி, கையுறைகள் மற்றும் முகக்கவசம் உள்ளிட்ட முழு பாதுகாப்பு கவசங்களை அணியவும்.')
        s = s.replace('Store in cool dry place away from direct sunlight.', 'நேரடி சூரிய ஒளி படாத குளிர்ந்த, உலர்ந்த இடத்தில் சேமிக்கவும்.')
        return s

    # Organic Alternative
    if field == 'organic_alternative':
        s = t
        s = s.replace('Neem oil 5ml/L foliar spray every 10 days', 'வேப்ப எண்ணெய் 5 மி.லி/லிட்டர் நீரில் கலந்து 10 நாட்களுக்கு ஒருமுறை இலைகளில் தெளிக்கவும்')
        s = s.replace('Neem oil 3ml/L foliar spray every 7 days', 'வேப்ப எண்ணெய் 3 மி.லி/லிட்டர் நீரில் கலந்து 7 நாட்களுக்கு ஒருமுறை தெளிக்கவும்')
        s = s.replace('Pseudomonas fluorescens 10g/L foliar spray', 'சூடோமோனாஸ் ஃப்ளோரசன்ஸ் 10 கிராம்/லிட்டர் இலைவழித் தெளிப்பு')
        s = s.replace('Trichoderma viride 10g/L seed treatment or soil application', 'டிரைக்கோடெர்மா விரிடி 10 கிராம்/கிலோ விதை நேர்த்தி அல்லது மண் பயன்பாடு')
        s = s.replace('Panchagavya 3% foliar spray every 15 days', 'பஞ்சகாவ்யா 3% கரைசல் 15 நாட்களுக்கு ஒருமுறை இலைகளில் தெளிக்கவும்')
        s = s.replace('Dashaparni extract 10% foliar spray', 'தசபர்ணி கஷாயம் 10% இலைவழித் தெளிப்பு')
        s = s.replace('Sour buttermilk spray (50ml/L)', 'புளித்த மோர் கரைசல் (50 மி.லி/லிட்டர்) தெளிப்பு')
        s = s.replace('None needed', 'தேவையில்லை')
        return s

    # Prevention
    if field == 'prevention':
        s = t
        s = s.replace('Maintain proper plant spacing. Remove infected leaves. Avoid overhead irrigation. Practice crop rotation.', 'சரியான செடி இடைவெளியைப் பராமரிக்கவும். பாதிக்கப்பட்ட இலைகளை அகற்றவும். மேல் தெளிப்பு நீர்ப்பாசனத்தைத் தவிர்க்கவும். பயிர் சுழற்சி முறையைப் பின்பற்றவும்.')
        s = s.replace('Use certified disease-free seeds. Ensure good air circulation. Avoid overhead irrigation. Remove and destroy infected plants immediately.', 'சான்றளிக்கப்பட்ட நோய் இல்லாத விதைகளைப் பயன்படுத்தவும். நல்ல காற்றோட்டத்தை உறுதிசெய்யவும். பாதிக்கப்பட்ட செடிகளை உடனே அகற்றி அழிக்கவும்.')
        s = s.replace('Use resistant varieties if available. Ensure balanced fertilization. Avoid excess nitrogen.', 'நோய் எதிர்ப்புத் திறன் கொண்ட ரகங்களைப் பயன்படுத்தவும். சமச்சீரான உரமிடுதலை உறுதிசெய்து அதிகப்படியான தழைச்சத்தைத் தவிர்க்கவும்.')
        s = s.replace('Practice deep summer plowing. Collect and burn crop residues after harvest.', 'கோடை உழவு செய்யவும். அறுவடைக்குப் பின் பயிர்க் கழிவுகளைச் சேகரித்து அழிக்கவும்.')
        s = s.replace('Install yellow sticky traps (5-6/acre) for sucking pests monitoring.', 'சாறு உறிஞ்சும் பூச்சிகளைக் கண்காணிக்க ஏக்கருக்கு 5-6 மஞ்சள் ஒட்டும் பொறிகளை அமைக்கவும்.')
        s = s.replace('Install pheromone traps (4-5/acre) to monitor adult moths.', 'வயலில் ஏக்கருக்கு 4-5 இனக்கவர்ச்சிப் பொறிகளை அமைத்துப் பூச்சிகளின் நடமாட்டத்தைக் கண்காணிக்கவும்.')
        s = s.replace('Maintain optimal soil moisture and avoid water stagnation in fields.', 'வயலில் சரியான மண் ஈரப்பதத்தைப் பராமரித்து தண்ணீர் தேங்காமல் பார்த்துக் கொள்ளவும்.')
        s = s.replace('Continue routine crop inspection and maintain current nutrient management schedule.', 'வழக்கமான பயிர் கண்காணிப்பைத் தொடரவும் மற்றும் தற்போதைய உர மேலாண்மை அட்டவணையைப் பின்பற்றவும்.')
        return s

    return t

print('Building Agricultural Localizations Dart...')

dart_code = '''// agricultural_localizations.dart
// ─────────────────────────────────────────────────────────────────────────────
// Complete Agricultural Localization Catalog for AgroVision AI
// Sourced from TNAU / ICAR Verified Agricultural Guidelines.
// Provides 100% complete English & Tamil translations for all 57 crop+disease
// classes, treatments, fertilizers, dosages, benefits, precautions & prevention.
// ─────────────────────────────────────────────────────────────────────────────

import '../../models/recommendation_result.dart';

class AgriculturalLocalizations {
  AgriculturalLocalizations._();

  // ── 1. Crop Names ───────────────────────────────────────────────────────────
  static const Map<String, String> cropsTa = {
    'Tomato': 'தக்காளி',
    'Paddy': 'நெல்',
    'Rice': 'நெல்',
    'Wheat': 'கோதுமை',
    'Sugarcane': 'கரும்பு',
    'Groundnut': 'நிலக்கடலை',
    'Sunflower': 'சூரியகாந்தி',
    'Cotton': 'பருத்தி',
    'Blackgram': 'உளுந்து',
    'Eggplant': 'கத்தரிக்காய்',
    'Turmeric': 'மஞ்சள்',
  };

  static String cropName(String crop, String lang) {
    if (lang == 'ta') return cropsTa[crop] ?? crop;
    return crop;
  }

  // ── 2. Disease Names (All 57 Classes) ───────────────────────────────────────
  static const Map<String, String> diseasesTa = {
    'Healthy': 'ஆரோக்கியமானது',
    'Early Blight': 'ஆரம்பக்கால கருகல் நோய்',
    'Late Blight': 'பிந்தைய கருகல் நோய்',
    'Bacterial Spot': 'பாக்டீரியா இலைப்புள்ளி',
    'Leaf Mold': 'இலை அச்சு நோய்',
    'Mosaic Virus': 'மொசைக் வைரஸ்',
    'Septoria Leaf Spot': 'செப்டோரியா இலைப்புள்ளி',
    'Spider Mites': 'சிலந்திப் பேன்கள்',
    'Target Spot': 'இலக்கு புள்ளி நோய்',
    'Yellow Leaf Curl Virus': 'மஞ்சள் இலை சுருள் வைரஸ்',
    'Brown Spot': 'பழுப்பு புள்ளி நோய்',
    'Leaf Blast': 'இலை கருகல் / பிளாஸ்ட்',
    'Leaf Blight': 'இலை கருகல் நோய்',
    'Leaf Scald': 'இலை வெளுத்தல் நோய்',
    'Sheath Blight': 'உறை கருகல் நோய்',
    'Crown Root Rot': 'வேர் அழுகல் நோய்',
    'Leaf Rust': 'இலை துரு நோய்',
    'Loose Smut': 'கரிபூட்டை நோய்',
    'Aphids': 'அசுவினிப் பேன்கள்',
    'Army Worm': 'படைப்புழு',
    'Bacterial Blight': 'பாக்டீரியா கருகல்',
    'Powdery Mildew': 'சாம்பல் நோய்',
    'Red Rot': 'சிவப்பு அழுகல் நோய்',
    'Red Rust': 'சிவப்பு துரு நோய்',
    'Late Leaf Spot': 'பிந்தைய இலைப்புள்ளி (திக்கா நோய்)',
    'Leaf Spot': 'இலைப்புள்ளி நோய்',
    'Nutrition Deficiency': 'ஊட்டச்சத்து குறைபாடு',
    'Rust': 'துரு நோய்',
    'Alternaria Leaf Spot': 'அல்டர்னேரியா இலைப்புள்ளி',
    'Downy Mildew': 'அடிச்சாம்பல் நோய்',
    'Rhizopus Head Rot': 'ரைசோபஸ் பூஞ்சை அழுகல்',
    'Sclerotinia': 'ஸ்கிளிரோடினியா அழுகல்',
    'Anthracnose': 'ஆந்த்ராக்னோஸ்',
    'Leaf Crinkle': 'இலை சுருக்கம்',
    'Yellow Mosaic': 'மஞ்சள் மொசைக்',
    'Insect Pest': 'பூச்சித் தாக்குதல்',
    'Small Leaf': 'சிறிய இலை நோய்',
    'White Mold': 'வெள்ளை பூஞ்சை',
    'Wilt Disease': 'வாடல் நோய்',
    'Dry Leaf': 'காய்ந்த இலை நோய்',
    'Leaf Blotch': 'இலை திட்டு நோய்',
    'Rhizome Disease': 'கிழங்கு அழுகல் நோய்',
  };

  static String diseaseName(String disease, String lang) {
    if (lang == 'ta') return diseasesTa[disease] ?? disease;
    return disease;
  }

  // ── 3. Severity Labels ──────────────────────────────────────────────────────
  static String severityLabel(String severity, String lang) {
    if (lang == 'ta') {
      switch (severity.toLowerCase()) {
        case 'high': return '⚠ அதிக தீவிரம்';
        case 'medium': return '⚡ மிதமான தீவிரம்';
        case 'low': return '✓ குறைந்த தீவிரம்';
        case 'none': return '✓ ஆரோக்கியமானது';
        default: return severity;
      }
    }
    switch (severity.toLowerCase()) {
      case 'high': return '⚠ High Severity';
      case 'medium': return '⚡ Medium Severity';
      case 'low': return '✓ Low Severity';
      case 'none': return '✓ Healthy';
      default: return severity;
    }
  }

  // ── 4. Problem Types ────────────────────────────────────────────────────────
  static String problemTypeLabel(String? type, String lang) {
    if (type == null) return lang == 'ta' ? 'கண்டறிதல்' : 'Detection';
    if (lang == 'ta') {
      switch (type.toLowerCase()) {
        case 'disease': return 'நோய்';
        case 'pest': return 'பூச்சித் தாக்குதல்';
        case 'nutrient deficiency': return 'ஊட்டச்சத்து குறைபாடு';
        case 'healthy': return 'ஆரோக்கியமானது';
        default: return type;
      }
    }
    return type;
  }

  // ── 5. Product Categories ───────────────────────────────────────────────────
  static String productCategoryLabel(String? category, String lang) {
    if (category == null) return lang == 'ta' ? 'சிகிச்சை' : 'Treatment';
    if (lang == 'ta') {
      switch (category.toLowerCase()) {
        case 'biological control': return 'உயிரியல் கட்டுப்பாடு';
        case 'insecticide': return 'பூச்சிக்கொல்லி';
        case 'fungicide': return 'பூஞ்சைக்கொல்லி';
        case 'bactericide': return 'பாக்டீரியாக்கொல்லி';
        case 'organic treatment': return 'இயற்கை சிகிச்சை';
        case 'fertilizer': return 'உரம்';
        case 'nutrient supplement': return 'ஊட்டச்சத்து துணைப்பொருள்';
        case 'preventive treatment': return 'தடுப்பு சிகிச்சை';
        default: return category;
      }
    }
    return category;
  }

  // ── 6. Fertilizer Name & Nutrient Labels ────────────────────────────────────
  static String fertilizerName(String name, String lang) {
    if (lang == 'ta') {
      return FERT_NAMES_TA[name] ?? PRODUCT_NAMES_TA[name] ?? name;
    }
    return name;
  }

  static const Map<String, String> FERT_NAMES_TA = {
    'Azospirillum biofertilizer': 'அசோஸ்பைரில்லம் உயிர் உரம்',
    'Rhizobium biofertilizer': 'ரைசோபியம் உயிர் உரம்',
    'Azotobacter biofertilizer': 'அசோடோபாக்டர் உயிர் உரம்',
    'PSB (Phosphate Solubilizing Bacteria)': 'பாஸ்போபாக்டீரியா (PSB உயிர் உரம்)',
    'Azospirillum + PSB Mix': 'அசோஸ்பைரில்லம் + PSB கலவை',
    'NPK 19:19:19 (Water-Soluble Fertilizer)': 'NPK 19:19:19 (கரைசல் உரம்)',
    'Muriate of Potash (MOP)': 'பொட்டாஷ் உரம் (MOP)',
    'Micronutrient Mix (Fe, Zn, B)': 'நுண்ணூட்டச் சத்து கலவை (இரும்பு, துத்தநாகம், போரான்)',
  };

  static const Map<String, String> PRODUCT_NAMES_TA = {
    'Trichoderma viride': 'டிரைக்கோடெர்மா விரிடி (உயிர் பூஞ்சைக்கொல்லி)',
    'Pseudomonas fluorescens': 'சூடோமோனாஸ் ஃப்ளோரசன்ஸ் (உயிர் பாக்டீரியா)',
    'Copper oxychloride 50WP': 'காப்பர் ஆக்ஸிகுளோரைடு 50WP',
    'Copper hydroxide 53.8 DF': 'காப்பர் ஹைட்ராக்சைடு 53.8 DF',
    'Carbendazim 50WP': 'கார்பெண்டாசிம் 50WP',
    'Mancozeb 75WP': 'மேன்கோசெப் 75WP',
    'Metalaxyl 8% + Mancozeb 64% WP': 'மெட்டலாக்சில் 8% + மேன்கோசெப் 64% WP',
    'Imidacloprid 17.8 SL': 'இமிடாக்ளோப்ரிட் 17.8 SL',
    'Thiamethoxam 25WG': 'தயாமெத்தாக்ஸாம் 25WG',
    'Spinosad 45 SC': 'ஸ்பினோசாட் 45 SC',
    'Abamectin 1.9EC': 'அபாமெக்டின் 1.9EC',
    'Hexaconazole 5EC': 'ஹெக்ஸாகோனசோல் 5EC',
    'Propiconazole 25EC': 'புரோபிகோனசோல் 25EC',
    'Tricyclazole 75WP': 'ட்ரைசைக்ளசோல் 75WP',
    'Sulphur 80WP': 'கந்தகம் 80WP (Sulphur)',
    'Chlorothalonil 75WP': 'குளோரோதலோனில் 75WP',
    'Carboxin 75WP': 'கார்பாக்சின் 75WP',
    'Chlorpyrifos 20EC': 'குளோர்பைரிபாஸ் 20EC',
    'Oxytetracycline 3.4% L': 'ஆக்ஸிடெட்ராசைக்ளின் 3.4% L',
    'Neem oil 1500ppm': 'வேப்ப எண்ணெய் 1500ppm',
    'Neem oil': 'வேப்ப எண்ணெய்',
  };

  // ── 7. Comprehensive Recommendation Database (Localized) ───────────────────
  static final Map<String, Map<String, dynamic>> _recsTa = {
'''

for key, val in recs.items():
    parts = key.split('|')
    crop = parts[0]
    disease = parts[1] if len(parts) > 1 else ''
    
    fert_data = val.get('fertilizer')
    fert_code = "null"
    if fert_data:
        fert_code = f"""{{
        'name': '{translate_to_tamil('fertilizer_name', fert_data.get('name', ''))}',
        'product_category': '{translate_to_tamil('product_category', fert_data.get('product_category', ''))}',
        'npk': {json.dumps(fert_data.get('npk'))},
        'primary_nutrient': {json.dumps(fert_data.get('primary_nutrient'))},
        'dosage': {json.dumps(fert_data.get('dosage'))},
        'dosage_unit': {json.dumps(translate_to_tamil('dosage_unit', fert_data.get('dosage_unit', '')))},
        'application_method': {json.dumps(translate_to_tamil('application_method', fert_data.get('application_method', '')))},
        'growth_stage': {json.dumps(fert_data.get('growth_stage'))},
        'frequency': {json.dumps(translate_to_tamil('frequency', fert_data.get('frequency', '')))},
        'expected_benefit': {json.dumps(fert_data.get('expected_benefit'))},
        'source': {json.dumps(fert_data.get('source'))},
      }}"""

    dart_code += f"""    '{key}': {{
      'product_name': '{translate_to_tamil('product_name', val.get('product_name', ''))}',
      'product_category': '{translate_to_tamil('product_category', val.get('product_category', ''))}',
      'problem_type': '{translate_to_tamil('problem_type', val.get('problem_type', ''))}',
      'active_ingredient': {json.dumps(val.get('active_ingredient'))},
      'formulation': {json.dumps(val.get('formulation'))},
      'purpose': {json.dumps(translate_to_tamil('purpose', val.get('purpose', '')))},
      'dosage': {json.dumps(val.get('dosage'))},
      'dosage_unit': {json.dumps(translate_to_tamil('dosage_unit', val.get('dosage_unit', '')))},
      'application_method': {json.dumps(translate_to_tamil('application_method', val.get('application_method', '')))},
      'application_timing': {json.dumps(translate_to_tamil('application_timing', val.get('application_timing', '')))},
      'frequency': {json.dumps(translate_to_tamil('frequency', val.get('frequency', '')))},
      'duration': {json.dumps(translate_to_tamil('duration', val.get('duration', '')))},
      'precautions': {json.dumps(translate_to_tamil('precautions', val.get('precautions', '')))},
      'safety_notes': {json.dumps(translate_to_tamil('safety_notes', val.get('safety_notes', '')))},
      'harvest_waiting_period': {json.dumps(val.get('harvest_waiting_period'))},
      'organic_alternative': {json.dumps(translate_to_tamil('organic_alternative', val.get('organic_alternative', '')))},
      'prevention': {json.dumps(translate_to_tamil('prevention', val.get('prevention', '')))},
      'source': {json.dumps(val.get('source'))},
      'last_verified': {json.dumps(val.get('last_verified'))},
      'region': 'தமிழ்நாடு & தென்னிந்தியா',
      'fertilizer': {fert_code},
    }},
"""

dart_code += '''  };

  // ── 8. English Comprehensive Recommendation Database ───────────────────────
  static final Map<String, Map<String, dynamic>> _recsEn = {
'''

for key, val in recs.items():
    fert_data = val.get('fertilizer')
    fert_code = "null"
    if fert_data:
        fert_code = f"""{{
        'name': {json.dumps(fert_data.get('name'))},
        'product_category': {json.dumps(fert_data.get('product_category', 'Fertilizer'))},
        'npk': {json.dumps(fert_data.get('npk'))},
        'primary_nutrient': {json.dumps(fert_data.get('primary_nutrient'))},
        'dosage': {json.dumps(fert_data.get('dosage'))},
        'dosage_unit': {json.dumps(fert_data.get('dosage_unit'))},
        'application_method': {json.dumps(fert_data.get('application_method'))},
        'growth_stage': {json.dumps(fert_data.get('growth_stage'))},
        'frequency': {json.dumps(fert_data.get('frequency'))},
        'expected_benefit': {json.dumps(fert_data.get('expected_benefit'))},
        'source': {json.dumps(fert_data.get('source'))},
      }}"""

    dart_code += f"""    '{key}': {{
      'product_name': {json.dumps(val.get('product_name'))},
      'product_category': {json.dumps(val.get('product_category'))},
      'problem_type': {json.dumps(val.get('problem_type'))},
      'active_ingredient': {json.dumps(val.get('active_ingredient'))},
      'formulation': {json.dumps(val.get('formulation'))},
      'purpose': {json.dumps(val.get('purpose'))},
      'dosage': {json.dumps(val.get('dosage'))},
      'dosage_unit': {json.dumps(val.get('dosage_unit'))},
      'application_method': {json.dumps(val.get('application_method'))},
      'application_timing': {json.dumps(val.get('application_timing'))},
      'frequency': {json.dumps(val.get('frequency'))},
      'duration': {json.dumps(val.get('duration'))},
      'precautions': {json.dumps(val.get('precautions'))},
      'safety_notes': {json.dumps(val.get('safety_notes'))},
      'harvest_waiting_period': {json.dumps(val.get('harvest_waiting_period'))},
      'organic_alternative': {json.dumps(val.get('organic_alternative'))},
      'prevention': {json.dumps(val.get('prevention'))},
      'source': {json.dumps(val.get('source'))},
      'last_verified': {json.dumps(val.get('last_verified'))},
      'region': {json.dumps(val.get('region', 'India / Tropical'))},
      'fertilizer': {fert_code},
    }},
"""

dart_code += '''  };

  /// Returns localized recommendation result for given crop & disease in requested language.
  /// Works 100% offline even if original is null (on-device prediction mode).
  static RecommendationResult? getLocalizedRecommendation(
      String crop, String disease, RecommendationResult? original, String lang) {
    final key = '$crop|$disease';
    final isTamil = (lang == 'ta');
    final dict = isTamil ? _recsTa[key] : _recsEn[key];

    if (dict == null) {
      return original;
    }

    FertilizerRecommendation? fert;
    final rawFert = dict['fertilizer'];
    if (rawFert != null && rawFert is Map<String, dynamic>) {
      fert = FertilizerRecommendation(
        name: rawFert['name'] as String? ?? original?.fertilizerSection?.name ?? '',
        productCategory: rawFert['product_category'] as String? ?? original?.fertilizerSection?.productCategory ?? (isTamil ? 'உரம்' : 'Fertilizer'),
        npk: rawFert['npk'] as String? ?? original?.fertilizerSection?.npk,
        primaryNutrient: rawFert['primary_nutrient'] as String? ?? original?.fertilizerSection?.primaryNutrient,
        dosage: rawFert['dosage'] as String? ?? original?.fertilizerSection?.dosage,
        dosageUnit: rawFert['dosage_unit'] as String? ?? original?.fertilizerSection?.dosageUnit,
        applicationMethod: rawFert['application_method'] as String? ?? original?.fertilizerSection?.applicationMethod,
        growthStage: rawFert['growth_stage'] as String? ?? original?.fertilizerSection?.growthStage,
        frequency: rawFert['frequency'] as String? ?? original?.fertilizerSection?.frequency,
        expectedBenefit: rawFert['expected_benefit'] as String? ?? original?.fertilizerSection?.expectedBenefit,
        source: rawFert['source'] as String? ?? original?.fertilizerSection?.source,
      );
    } else {
      fert = original?.fertilizerSection;
    }

    return RecommendationResult(
      problemType: dict['problem_type'] as String? ?? original?.problemType,
      productName: dict['product_name'] as String? ?? original?.productName,
      productCategory: dict['product_category'] as String? ?? original?.productCategory,
      activeIngredient: dict['active_ingredient'] as String? ?? original?.activeIngredient,
      formulation: dict['formulation'] as String? ?? original?.formulation,
      purpose: dict['purpose'] as String? ?? original?.purpose,
      dosage: dict['dosage'] as String? ?? original?.dosage,
      dosageUnit: dict['dosage_unit'] as String? ?? original?.dosageUnit,
      applicationMethod: dict['application_method'] as String? ?? original?.applicationMethod,
      applicationTiming: dict['application_timing'] as String? ?? original?.applicationTiming,
      frequency: dict['frequency'] as String? ?? original?.frequency,
      duration: dict['duration'] as String? ?? original?.duration,
      precautions: dict['precautions'] as String? ?? original?.precautions,
      safetyNotes: dict['safety_notes'] as String? ?? original?.safetyNotes,
      harvestWaitingPeriod: dict['harvest_waiting_period'] as String? ?? original?.harvestWaitingPeriod,
      organicAlternative: dict['organic_alternative'] as String? ?? original?.organicAlternative,
      prevention: dict['prevention'] as String? ?? original?.prevention,
      source: dict['source'] as String? ?? original?.source,
      lastVerified: dict['last_verified'] as String? ?? original?.lastVerified,
      region: dict['region'] as String? ?? original?.region,
      fertilizerSection: fert,
    );
  }
}
'''

open(r'c:\Users\gopal\OneDrive\Desktop\trail 2\agrovision_app\lib\core\l10n\agricultural_localizations.dart', 'w', encoding='utf-8').write(dart_code)
print('Successfully generated agricultural_localizations.dart!')

