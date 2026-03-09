<template>
  <div class="min-h-screen bg-gray-100 flex justify-center p-4">
    <div class="bg-white shadow-lg rounded-lg w-full max-w-4xl p-6">

      <!-- Header -->
      <div class="text-center mb-6">
        <h2 class="text-sm">Republic of the Philippines</h2>
        <h1 class="text-lg font-bold">CITY OF SANTIAGO</h1>
        <p class="text-sm">Public Employment Service Office</p>

        <h2 class="text-xl font-semibold mt-4">Citizen's Feedback Form</h2>
        <p class="text-sm text-gray-600">
          We intend to serve you better. Kindly fill-out this feedback form.
        </p>
      </div>

      <!-- Activity Info -->
      <div class="grid md:grid-cols-3 gap-4 mb-6">
        <div>
          <label class="font-semibold">Program / Activity</label>
          <input v-model="form.program" type="text" class="input">
        </div>

        <div>
          <label class="font-semibold">Venue / School</label>
          <input v-model="form.venue" type="text" class="input">
        </div>

        <div>
          <label class="font-semibold">Date of Activity</label>
          <input v-model="form.date" type="date" class="input">
        </div>
      </div>

      <!-- Rating Legend -->
      <div class="text-sm mb-2">
        Legend:
        <span class="ml-2">1 - Poor</span>
        <span class="ml-2">2 - Average</span>
        <span class="ml-2">3 - Satisfactory</span>
        <span class="ml-2">4 - Very Satisfactory</span>
        <span class="ml-2">5 - Excellent</span>
      </div>

      <!-- Table -->
      <div class="overflow-x-auto">
        <table class="w-full border border-gray-400 text-sm">
          <thead class="bg-gray-200">
            <tr>
              <th class="border p-2 text-left">Criteria</th>
              <th v-for="n in 5" :key="n" class="border p-2 text-center">{{ n }}</th>
              <th class="border p-2">Remarks</th>
            </tr>
          </thead>

          <tbody>
            <tr v-for="(item, index) in criteria" :key="index">
              <td class="border p-2">{{ item }}</td>

              <td
                v-for="n in 5"
                :key="n"
                class="border text-center"
              >
                <input
                  type="radio"
                  :name="'rate' + index"
                  :value="n"
                  v-model="ratings[index]"
                >
              </td>

              <td class="border p-1">
                <input
                  type="text"
                  v-model="remarks[index]"
                  class="w-full p-1 border rounded"
                >
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Overall Rating -->
      <div class="mt-6">
        <label class="font-semibold">Overall Rating</label>
        <select v-model="form.overall" class="input">
          <option disabled value="">Select Rating</option>
          <option v-for="n in 5" :key="n" :value="n">{{ n }}</option>
        </select>
      </div>

      <!-- Suggestions -->
      <div class="mt-6">
        <label class="font-semibold">Suggestion / Recommendation</label>
        <textarea
          v-model="form.suggestion"
          rows="3"
          class="input"
        ></textarea>
      </div>

      <!-- Signature -->
      <div class="mt-6 flex justify-end">
        <div class="w-64">
          <label class="font-semibold">Signature</label>
          <input type="text" v-model="form.signature" class="input">
        </div>
      </div>

      <!-- Submit -->
      <div class="mt-6 text-center">
        <button
          @click="submitForm"
          class="bg-blue-600 text-white px-6 py-2 rounded hover:bg-blue-700"
        >
          Submit Feedback
        </button>
      </div>

    </div>
  </div>
</template>

<script>
export default {
  name: "FeedbackForm",

  data() {
    return {
      form: {
        program: "",
        venue: "",
        date: "",
        overall: "",
        suggestion: "",
        signature: ""
      },

      criteria: [
        "Speaker 1 - Contents",
        "Speaker 1 - Level of Interaction",
        "Speaker 1 - Mastery of Topic",
        "Speaker 2 - Contents",
        "Speaker 2 - Level of Interaction",
        "Speaker 2 - Mastery of Topic",
        "Speaker 3 - Contents",
        "Speaker 3 - Level of Interaction",
        "Speaker 3 - Mastery of Topic"
      ],

      ratings: {},
      remarks: {}
    }
  },

  methods: {
    submitForm() {
      const payload = {
        ...this.form,
        ratings: this.ratings,
        remarks: this.remarks
      }

      console.log(payload)

      alert("Feedback Submitted!")
    }
  }
}
</script>

<style scoped>
.input{
  width:100%;
  border:1px solid #ccc;
  padding:8px;
  border-radius:6px;
}
</style>