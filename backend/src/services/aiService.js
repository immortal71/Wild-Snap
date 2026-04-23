const axios = require('axios');
const FormData = require('form-data');

const INATURALIST_API_URL = process.env.INATURALIST_API_URL || 'https://api.inaturalist.org/v1';

const CONFIDENCE = {
  AUTO_ACCEPT: 85,
  NEEDS_CONFIRMATION: 70,
  LOW_CONFIDENCE: 50,
};

/**
 * Submit an image Buffer to iNaturalist computer vision for identification.
 * @param {Buffer} photoBuffer - image data
 * @param {string} [filename]
 * @returns {Promise<{topResult, status, suggestions, rawResponse}>}
 */
async function identifyPhoto(photoBuffer, filename = 'photo.jpg') {
  if (!Buffer.isBuffer(photoBuffer)) {
    throw new TypeError('identifyPhoto requires a Buffer');
  }

  const form = new FormData();
  form.append('image', photoBuffer, { filename, contentType: 'image/jpeg' });

  let rawResponse;
  try {
    const response = await axios.post(
      `${INATURALIST_API_URL}/computervision/score_image`,
      form,
      {
        headers: form.getHeaders(),
        timeout: 30000,
      }
    );
    rawResponse = response.data;
  } catch (err) {
    if (err.response) {
      console.error('iNaturalist API error:', err.response.status, err.response.data);
    } else {
      console.error('iNaturalist request failed:', err.message);
    }
    return { topResult: null, status: 'api_error', suggestions: [], rawResponse: null };
  }

  const results = rawResponse.results || [];
  if (results.length === 0) {
    return { topResult: null, status: 'unrecognized', suggestions: [], rawResponse };
  }

  const suggestions = results.map((r) => ({
    taxon_id: r.taxon?.id,
    common_name: r.taxon?.preferred_common_name || r.taxon?.name,
    scientific_name: r.taxon?.name,
    score: Math.round((r.combined_score || r.vision_score || 0) * 100),
    iconic_taxon: r.taxon?.iconic_taxon_name,
  }));

  const topResult = suggestions[0];
  const score = topResult.score;

  let status;
  if (score >= CONFIDENCE.AUTO_ACCEPT) {
    status = 'auto_accept';
  } else if (score >= CONFIDENCE.NEEDS_CONFIRMATION) {
    status = 'needs_confirmation';
  } else if (score >= CONFIDENCE.LOW_CONFIDENCE) {
    status = 'low_confidence';
  } else {
    status = 'unrecognized';
  }

  return { topResult, status, suggestions, rawResponse };
}

/**
 * Find a matching animal row in our DB by iNaturalist suggestions.
 * Matches on scientific_name or common_name via ai_labels array.
 * @param {Array} suggestions
 * @param {Function} dbQuery - db.query function
 * @returns {Promise<Object|null>}
 */
async function matchAnimalFromSuggestions(suggestions, dbQuery) {
  for (const suggestion of suggestions.slice(0, 3)) {
    const { scientific_name, common_name } = suggestion;

    const res = await dbQuery(
      `SELECT * FROM animals
       WHERE lower(scientific_name) = lower($1)
          OR lower(common_name) = lower($2)
          OR $3 = ANY(SELECT lower(l) FROM unnest(ai_labels) AS l)
          OR $4 = ANY(SELECT lower(l) FROM unnest(ai_labels) AS l)
       LIMIT 1`,
      [
        scientific_name || '',
        common_name || '',
        (scientific_name || '').toLowerCase(),
        (common_name || '').toLowerCase(),
      ]
    );

    if (res.rows.length > 0) return res.rows[0];
  }
  return null;
}

module.exports = { identifyPhoto, matchAnimalFromSuggestions };
