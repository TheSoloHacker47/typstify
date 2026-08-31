# frozen_string_literal: true

require "spec_helper"

RSpec.describe Typstify::Workspace do
  def build(files, &block)
    with_templates(files) do
      described_class.build(source: "= Hi", data: nil, config: Typstify.config, &block)
    end
  end

  it "writes main.typ at the root, so shared imports resolve from any view depth" do
    build("a.typ" => "x") do |workspace|
      expect(workspace.main_path.basename.to_s).to eq("main.typ")
      expect(workspace.main_path.dirname).to eq(workspace.dir)
    end
  end

  it "writes an empty object when there is no data" do
    build("a.typ" => "x") do |workspace|
      expect(workspace.dir.join("data.json").read).to eq("{}")
    end
  end

  it "copies the shared directory in" do
    with_templates("shared/branding.typ" => "// brand", "shared/nested/more.typ" => "// more") do
      described_class.build(source: "= Hi", data: nil) do |workspace|
        expect(workspace.dir.join("shared/branding.typ")).to exist
        expect(workspace.dir.join("shared/nested/more.typ")).to exist
      end
    end
  end

  # A symlink inside the root points outside the root, which is exactly the
  # file-system access the workspace exists to remove.
  it "skips symlinks rather than following them out of the root" do
    with_templates("shared/real.typ" => "// real") do |root|
      File.symlink("/etc/hosts", root.join("shared/escape.typ"))

      described_class.build(source: "= Hi", data: nil) do |workspace|
        expect(workspace.dir.join("shared/real.typ")).to exist
        expect(workspace.dir.join("shared/escape.typ")).not_to exist
      end
    end
  end

  it "removes the directory afterwards" do
    captured = nil
    build("a.typ" => "x") { |workspace| captured = workspace.dir }

    expect(captured).not_to exist
  end

  it "removes the directory even when the block raises" do
    captured = nil

    expect do
      build("a.typ" => "x") do |workspace|
        captured = workspace.dir
        raise "boom"
      end
    end.to raise_error("boom")

    expect(captured).not_to exist
  end
end
