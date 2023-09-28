$(function () {
  function wire() {
    var removeNestedButtons = $("button.form__remove_nested_button");

    removeNestedButtons.off("click");
    removeNestedButtons.click(function (e) {
      e.preventDefault();
      var button = $(this);
      var nestedField = button.closest(".form__nested_fields");

      nestedField.remove();
    });

    var addNestedButtons = $("button.form__add_nested_button");
    addNestedButtons.off("click");
    addNestedButtons.click(function (e) {
      e.preventDefault();
      var button = $(this);
      var nestedFields = button.siblings("template.form__nested_fields");

      var content = nestedFields
        .html()
        .replace(/NEW_OBJECT/g, new Date().getTime());

      $(content).insertAfter(button.siblings().last());

      wire();
    });
  }

  wire();

  // var enableGemScopeCheckboxes = $(
  //   "#push_rubygem, #yank_rubygem, #add_owner, #remove_owner"
  // );
  // var hiddenRubygemId = "hidden_api_key_rubygem_id";
  // toggleGemSelector();

  // enableGemScopeCheckboxes.click(function () {
  //   toggleGemSelector();
  // });

  // function toggleGemSelector() {
  //   var isApplicableGemScopeSelected = enableGemScopeCheckboxes.is(":checked");
  //   var gemScopeSelector = $("#api_key_rubygem_id");

  //   if (isApplicableGemScopeSelected) {
  //     gemScopeSelector.removeAttr("disabled");
  //     removeHiddenRubygemField();
  //   } else {
  //     gemScopeSelector.val("");
  //     gemScopeSelector.prop("disabled", true);
  //     addHiddenRubygemField();
  //   }
  // }

  // function addHiddenRubygemField() {
  //   $("<input>")
  //     .attr({
  //       type: "hidden",
  //       id: hiddenRubygemId,
  //       name: "api_key[rubygem_id]",
  //       value: "",
  //     })
  //     .appendTo(".t-body form .api_key_rubygem_id_form");
  // }

  // function removeHiddenRubygemField() {
  //   $("#" + hiddenRubygemId + ":hidden").remove();
  // }
});
